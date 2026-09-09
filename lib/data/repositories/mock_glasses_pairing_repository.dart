import 'dart:async';
import 'dart:math';

import '../models/glasses_device.dart';
import '../models/glasses_device_status.dart';
import 'glasses_pairing_repository.dart';

class MockGlassesPairingRepository implements GlassesPairingRepository {
  final _random = Random();
  bool _isConnected = false;
  
  Timer? _telemetryTimer;
  StreamController<GlassesDeviceStatus>? _telemetryController;

  @override
  Stream<List<GlassesDevice>> scanDevices() async* {
    if (_random.nextDouble() < 0.05) {
      throw BluetoothDisabledException("Bluetooth is disabled on this device.");
    }

    var devices = [
      const GlassesDevice(id: 'ht-sg-001', name: 'Hand Tech Pro 1', rssi: -60, batteryLevel: 85),
      const GlassesDevice(id: 'ht-sg-002', name: 'Hand Tech Lite', rssi: -80, batteryLevel: 42),
    ];

    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      
      devices = devices.map((d) {
        final rssiChange = _random.nextInt(11) - 5;
        return d.copyWith(
          rssi: (d.rssi + rssiChange).clamp(-100, -30),
        );
      }).toList();
      
      yield devices;
    }
  }

  @override
  Future<bool> connectToDevice(String deviceId) async {
    await Future.delayed(const Duration(seconds: 3));

    if (_random.nextDouble() < 0.1) {
      throw DeviceNotFoundException("Device $deviceId went out of range.");
    }
    
    if (_random.nextDouble() < 0.1) {
      throw GattCommunicationException("Failed to negotiate GATT MTU.");
    }

    _isConnected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _isConnected = false;
    _telemetryTimer?.cancel();
    _telemetryController?.close();
  }

  @override
  Stream<GlassesDeviceStatus> getTelemetryStream() {
    if (!_isConnected) {
      throw Exception("Cannot get telemetry while disconnected.");
    }
    
    _telemetryController?.close();
    _telemetryController = StreamController<GlassesDeviceStatus>();
    
    int currentBattery = 85;
    
    _telemetryTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }
      
      if (_random.nextDouble() < 0.2) {
        currentBattery = max(0, currentBattery - 1);
      }
      
      if (!_telemetryController!.isClosed) {
        _telemetryController!.add(GlassesDeviceStatus(
          batteryLevel: currentBattery,
          firmwareVersion: "v1.4.2-beta",
          isDualCameraActive: _random.nextBool(),
        ));
      }
    });

    return _telemetryController!.stream;
  }
}
