import '../models/glasses_device.dart';
import '../models/glasses_device_status.dart';

class BleTimeoutException implements Exception {
  final String message;
  BleTimeoutException(this.message);
}

class DeviceNotFoundException implements Exception {
  final String message;
  DeviceNotFoundException(this.message);
}

class BluetoothDisabledException implements Exception {
  final String message;
  BluetoothDisabledException(this.message);
}

class GattCommunicationException implements Exception {
  final String message;
  GattCommunicationException(this.message);
}

abstract class GlassesPairingRepository {
  Stream<List<GlassesDevice>> scanDevices();
  Future<bool> connectToDevice(String deviceId);
  Future<void> disconnect();
  Stream<GlassesDeviceStatus> getTelemetryStream();
}
