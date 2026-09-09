class GlassesDeviceStatus {
  final int batteryLevel;
  final String firmwareVersion;
  final bool isDualCameraActive;

  const GlassesDeviceStatus({
    required this.batteryLevel,
    required this.firmwareVersion,
    required this.isDualCameraActive,
  });

  GlassesDeviceStatus copyWith({
    int? batteryLevel,
    String? firmwareVersion,
    bool? isDualCameraActive,
  }) {
    return GlassesDeviceStatus(
      batteryLevel: batteryLevel ?? this.batteryLevel,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      isDualCameraActive: isDualCameraActive ?? this.isDualCameraActive,
    );
  }
}
