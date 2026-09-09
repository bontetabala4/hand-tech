import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import '../models/camera_frame.dart';
import 'camera_stream_repository.dart';

class MockCameraStreamRepository implements CameraStreamRepository {
  final _random = Random();
  StreamController<CameraFrame>? _controller;
  Timer? _timer;
  bool _isActive = false;

  @override
  Stream<CameraFrame> getVideoStream() {
    _controller ??= StreamController<CameraFrame>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<void> startCameraStream() async {
    if (_isActive) return;
    _isActive = true;
    
    int currentFps = 30;
    
    // 30 FPS ~ 33ms per frame
    _timer = Timer.periodic(const Duration(milliseconds: 33), (timer) {
      if (!_isActive) {
        timer.cancel();
        return;
      }
      
      // Simulate occasional frame drops
      if (_random.nextDouble() < 0.05) {
        currentFps = max(15, currentFps - 2);
        return; 
      } else {
        currentFps = min(30, currentFps + 1);
      }
      
      if (_controller != null && !_controller!.isClosed) {
        _controller!.add(CameraFrame(
          timestamp: DateTime.now(),
          frameData: Uint8List(0), // Placeholder simulated frame
          fps: currentFps,
          resolutionWidth: 1280,
          resolutionHeight: 720,
          isCameraActive: true,
        ));
      }
    });
  }

  @override
  Future<void> stopCameraStream() async {
    _isActive = false;
    _timer?.cancel();
  }
  
  @override
  Future<void> togglePictureInPicture(bool expand) async {
    // Typically PiP size is handled by UI. In a real integration, 
    // this might command the smart glasses to change streaming resolution or crop factor.
  }
}
