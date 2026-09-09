import 'dart:typed_data';

class CameraFrame {
  final DateTime timestamp;
  final Uint8List frameData;
  final int fps;
  final int resolutionWidth;
  final int resolutionHeight;
  final bool isCameraActive;

  const CameraFrame({
    required this.timestamp,
    required this.frameData,
    required this.fps,
    required this.resolutionWidth,
    required this.resolutionHeight,
    required this.isCameraActive,
  });
}
