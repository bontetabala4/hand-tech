import 'package:flutter_test/flutter_test.dart';
import 'package:hand_tech/data/repositories/ble_glasses_pairing_repository.dart';
import 'package:hand_tech/data/repositories/glasses_pairing_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BleGlassesPairingRepository Contract & Instantiation Tests', () {
    late BleGlassesPairingRepository repository;

    setUp(() {
      repository = BleGlassesPairingRepository();
    });

    test('should conform to GlassesPairingRepository interface', () {
      expect(repository, isA<GlassesPairingRepository>());
    });

    test('should throw GattCommunicationException when getting telemetry stream while disconnected', () {
      expect(() => repository.getTelemetryStream(), throwsA(isA<GattCommunicationException>()));
    });

    test('should disconnect cleanly without throwing errors when not connected', () async {
      await expectLater(repository.disconnect(), completes);
    });
  });
}
