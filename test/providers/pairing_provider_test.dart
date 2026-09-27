import 'dart:async';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hand_tech/data/models/glasses_device.dart';
import 'package:hand_tech/data/models/glasses_device_status.dart';
import 'package:hand_tech/data/repositories/glasses_pairing_repository.dart';
import 'package:hand_tech/data/services/haptic_feedback_service.dart';
import 'package:hand_tech/providers/hardware_providers.dart';
import 'package:hand_tech/providers/pairing_provider.dart';

class MockGlassesPairingRepository extends Mock implements GlassesPairingRepository {}

/// No-op haptic service — avoids HapticFeedback platform channel in tests.
class _FakeHapticService implements HapticFeedbackService {
  @override Future<void> selectionClick() async {}
  @override Future<void> successNotification() async {}
  @override Future<void> warningNotification() async {}
  @override Future<void> errorNotification() async {}
}

/// Shared overrides for every container in this file.
List<Override> _baseOverrides(MockGlassesPairingRepository repo) => [
      pairingRepositoryProvider.overrideWithValue(repo),
      hapticServiceProvider.overrideWithValue(_FakeHapticService()),
    ];

void main() {
  late MockGlassesPairingRepository mockRepository;
  late StreamController<List<GlassesDevice>> scanStreamController;
  late StreamController<GlassesDeviceStatus> telemetryStreamController;

  setUp(() {
    mockRepository = MockGlassesPairingRepository();
    scanStreamController = StreamController<List<GlassesDevice>>.broadcast();
    telemetryStreamController = StreamController<GlassesDeviceStatus>.broadcast();

    when(() => mockRepository.scanDevices())
        .thenAnswer((_) => scanStreamController.stream);
    when(() => mockRepository.getTelemetryStream())
        .thenAnswer((_) => telemetryStreamController.stream);
    when(() => mockRepository.disconnect())
        .thenAnswer((_) async {});
  });

  tearDown(() {
    scanStreamController.close();
    telemetryStreamController.close();
  });

  const testDevice = GlassesDevice(
    id: 'device_001',
    name: 'HandTech Smart Glasses',
    rssi: -55,
    batteryLevel: 95,
  );

  group('PairingNotifier Tests', () {
    test('Initial scan / unpaired state', () {
      final container = ProviderContainer(overrides: _baseOverrides(mockRepository));
      addTearDown(container.dispose);

      final state = container.read(pairingProvider);
      expect(state.status, PairingStatus.idle);
      expect(state.scannedDevices, isEmpty);
      expect(state.connectedDevice, isNull);
      expect(state.telemetry, isNull);
      expect(state.errorMessage, isNull);
    });

    test('Start scanning updates status to scanning and emits scanned devices', () async {
      final container = ProviderContainer(overrides: _baseOverrides(mockRepository));
      addTearDown(container.dispose);

      final notifier = container.read(pairingProvider.notifier);
      notifier.startScanning();

      expect(container.read(pairingProvider).status, PairingStatus.scanning);

      scanStreamController.add([testDevice]);
      await pumpEventQueue();

      final state = container.read(pairingProvider);
      expect(state.scannedDevices.length, 1);
      expect(state.scannedDevices.first.name, 'HandTech Smart Glasses');
    });

    test('Connection timeout handling emits error state when exception thrown', () async {
      when(() => mockRepository.connectToDevice('device_001'))
          .thenThrow(BleTimeoutException('Connection timed out after 15 seconds.'));

      final container = ProviderContainer(overrides: _baseOverrides(mockRepository));
      addTearDown(container.dispose);

      final notifier = container.read(pairingProvider.notifier);
      await notifier.connect(testDevice);

      final state = container.read(pairingProvider);
      expect(state.status, PairingStatus.error);
      expect(state.errorMessage, contains('Connection timed out after 15 seconds.'));
      expect(state.connectedDevice?.connectionStatus, ConnectionStatus.error);
    });

    test('Connection timeout handling triggers after 15 seconds timer', () {
      fakeAsync((async) {
        // Mock connection call that never completes
        when(() => mockRepository.connectToDevice('device_001'))
            .thenAnswer((_) => Completer<bool>().future);

        final container = ProviderContainer(overrides: _baseOverrides(mockRepository));

        final notifier = container.read(pairingProvider.notifier);
        notifier.connect(testDevice);

        expect(container.read(pairingProvider).status, PairingStatus.connecting);

        // Elapse 15 seconds for connection timer to fire
        async.elapse(const Duration(seconds: 15));

        final state = container.read(pairingProvider);
        expect(state.status, PairingStatus.error);
        expect(state.errorMessage, 'Connection timed out after 15 seconds.');
        expect(state.connectedDevice?.connectionStatus, ConnectionStatus.error);

        container.dispose();
      });
    });

    test('Exponential backoff retry logic and max reconnect attempts handling', () {
      fakeAsync((async) {
        when(() => mockRepository.connectToDevice('device_001'))
            .thenAnswer((_) async => true);

        final container = ProviderContainer(overrides: _baseOverrides(mockRepository));

        final notifier = container.read(pairingProvider.notifier);
        notifier.connect(testDevice);
        async.flushMicrotasks();

        expect(container.read(pairingProvider).status, PairingStatus.connected);

        // Emitting error in telemetry stream triggers auto-reconnect attempt 1
        telemetryStreamController.addError(Exception('BLE connection lost'));
        async.flushMicrotasks();

        // Attempt 1: backoff 2s
        var state = container.read(pairingProvider);
        expect(state.status, PairingStatus.connecting);
        expect(state.errorMessage, contains('Reconnecting in 2 seconds... (Attempt 1)'));

        async.elapse(const Duration(seconds: 2));
        async.flushMicrotasks();

        // Emitting error in telemetry stream triggers attempt 2
        telemetryStreamController.addError(Exception('BLE connection lost'));
        async.flushMicrotasks();

        // Attempt 2: backoff 4s
        state = container.read(pairingProvider);
        expect(state.status, PairingStatus.connecting);
        expect(state.errorMessage, contains('Reconnecting in 4 seconds... (Attempt 2)'));

        async.elapse(const Duration(seconds: 4));
        async.flushMicrotasks();

        // Emitting error in telemetry stream triggers attempt 3
        telemetryStreamController.addError(Exception('BLE connection lost'));
        async.flushMicrotasks();

        // Attempt 3: backoff 8s
        state = container.read(pairingProvider);
        expect(state.status, PairingStatus.connecting);
        expect(state.errorMessage, contains('Reconnecting in 8 seconds... (Attempt 3)'));

        async.elapse(const Duration(seconds: 8));
        async.flushMicrotasks();

        // Emitting error after max attempts -> max reconnect attempts reached
        telemetryStreamController.addError(Exception('BLE connection lost'));
        async.flushMicrotasks();

        state = container.read(pairingProvider);
        expect(state.status, PairingStatus.error);
        expect(state.errorMessage, 'Max reconnect attempts reached.');

        container.dispose();
      });
    });
  });
}
