enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

class GlassesDevice {
  final String id;
  final String name;
  final int rssi;
  final int batteryLevel;
  final ConnectionStatus connectionStatus;

  const GlassesDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.batteryLevel,
    this.connectionStatus = ConnectionStatus.disconnected,
  });

  GlassesDevice copyWith({
    String? id,
    String? name,
    int? rssi,
    int? batteryLevel,
    ConnectionStatus? connectionStatus,
  }) {
    return GlassesDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      connectionStatus: connectionStatus ?? this.connectionStatus,
    );
  }
}
