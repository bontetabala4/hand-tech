import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/glasses_device.dart';
import '../data/models/glasses_device_status.dart';
import '../data/repositories/glasses_pairing_repository.dart';
import '../data/repositories/mock_glasses_pairing_repository.dart';

final pairingRepositoryProvider = Provider<GlassesPairingRepository>((ref) {
  return MockGlassesPairingRepository();
});

enum PairingStatus {
  idle,
  scanning,
  connecting,
  connected,
  error,
}

class PairingState {
  final PairingStatus status;
  final List<GlassesDevice> scannedDevices;
  final GlassesDevice? connectedDevice;
  final GlassesDeviceStatus? telemetry;
  final String? errorMessage;

  PairingState({
    this.status = PairingStatus.idle,
    this.scannedDevices = const [],
    this.connectedDevice,
    this.telemetry,
    this.errorMessage,
  });

  PairingState copyWith({
    PairingStatus? status,
    List<GlassesDevice>? scannedDevices,
    GlassesDevice? connectedDevice,
    GlassesDeviceStatus? telemetry,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PairingState(
      status: status ?? this.status,
      scannedDevices: scannedDevices ?? this.scannedDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      telemetry: telemetry ?? this.telemetry,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class PairingNotifier extends StateNotifier<PairingState> {
  final GlassesPairingRepository _repository;
  
  StreamSubscription<List<GlassesDevice>>? _scanSub;
  StreamSubscription<GlassesDeviceStatus>? _telemetrySub;
  Timer? _connectionTimeoutTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 3;

  PairingNotifier(this._repository) : super(PairingState());

  void startScanning() {
    state = state.copyWith(status: PairingStatus.scanning, clearError: true);
    
    _scanSub?.cancel();
    _scanSub = _repository.scanDevices().listen(
      (devices) {
        state = state.copyWith(scannedDevices: devices);
      },
      onError: (error) {
        String msg = "Failed to scan.";
        if (error is BluetoothDisabledException) {
          msg = error.message;
        }
        state = state.copyWith(status: PairingStatus.error, errorMessage: msg);
      },
    );
  }

  void stopScanning() {
    _scanSub?.cancel();
    if (state.status == PairingStatus.scanning) {
      state = state.copyWith(status: PairingStatus.idle);
    }
  }

  Future<void> connect(GlassesDevice device) async {
    final isReconnecting = _reconnectAttempts > 0;
    stopScanning();
    state = state.copyWith(
      status: PairingStatus.connecting,
      connectedDevice: device.copyWith(connectionStatus: ConnectionStatus.connecting),
      clearError: !isReconnecting,
    );

    _connectionTimeoutTimer?.cancel();
    _connectionTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (state.status == PairingStatus.connecting) {
        _handleConnectionError(BleTimeoutException("Connection timed out after 15 seconds."));
      }
    });

    try {
      final success = await _repository.connectToDevice(device.id);
      _connectionTimeoutTimer?.cancel();
      
      if (success) {
        if (!isReconnecting) {
          _reconnectAttempts = 0;
        }
        state = state.copyWith(
          status: PairingStatus.connected,
          connectedDevice: device.copyWith(connectionStatus: ConnectionStatus.connected),
        );
        _startTelemetryStream();
      }
    } catch (e) {
      _connectionTimeoutTimer?.cancel();
      _handleConnectionError(e);
    }
  }

  void _startTelemetryStream() {
    _telemetrySub?.cancel();
    try {
      _telemetrySub = _repository.getTelemetryStream().listen(
        (telemetry) {
          state = state.copyWith(telemetry: telemetry);
        },
        onError: (error) {
          _handleDisconnect(autoReconnect: true);
        },
        onDone: () {
          _handleDisconnect(autoReconnect: true);
        },
      );
    } catch (e) {
       _handleConnectionError(e);
    }
  }

  Future<void> _handleDisconnect({bool autoReconnect = false}) async {
    _telemetrySub?.cancel();
    
    final device = state.connectedDevice;
    if (autoReconnect && device != null && _reconnectAttempts < _maxReconnectAttempts) {
      _reconnectAttempts++;
      final backoffSeconds = 1 << _reconnectAttempts; // 2, 4, 8 seconds
      
      state = state.copyWith(
        status: PairingStatus.connecting,
        errorMessage: "Connection lost. Reconnecting in $backoffSeconds seconds... (Attempt $_reconnectAttempts)",
      );
      
      await Future.delayed(Duration(seconds: backoffSeconds));
      if (state.status == PairingStatus.connecting) {
        connect(device);
      }
    } else {
       state = state.copyWith(
         status: PairingStatus.error,
         errorMessage: autoReconnect ? "Max reconnect attempts reached." : "Disconnected.",
         connectedDevice: device?.copyWith(connectionStatus: ConnectionStatus.disconnected),
       );
    }
  }

  void disconnect() {
    _reconnectAttempts = 0;
    _repository.disconnect();
    _scanSub?.cancel();
    _telemetrySub?.cancel();
    _connectionTimeoutTimer?.cancel();
    state = state.copyWith(
      status: PairingStatus.idle,
      connectedDevice: null,
      telemetry: null,
      clearError: true,
    );
  }

  void _handleConnectionError(Object error) {
    String msg = "Connection failed.";
    if (error is BleTimeoutException) {
      msg = error.message;
    } else if (error is DeviceNotFoundException) {
      msg = error.message;
    } else if (error is GattCommunicationException) {
      msg = error.message;
    }
    
    state = state.copyWith(
      status: PairingStatus.error,
      errorMessage: msg,
      connectedDevice: state.connectedDevice?.copyWith(connectionStatus: ConnectionStatus.error),
    );
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _telemetrySub?.cancel();
    _connectionTimeoutTimer?.cancel();
    _repository.disconnect();
    super.dispose();
  }
}

final pairingProvider = StateNotifierProvider<PairingNotifier, PairingState>((ref) {
  final repository = ref.watch(pairingRepositoryProvider);
  return PairingNotifier(repository);
});
