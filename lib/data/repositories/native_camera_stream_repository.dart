import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/camera_frame.dart';
import 'camera_stream_repository.dart';

class NativeCameraStreamRepository with WidgetsBindingObserver implements CameraStreamRepository {
  CameraController? _controller;
  StreamController<CameraFrame>? _frameStreamController;
  bool _isStreaming = false;
  bool _isPiPExpanded = false;
  int _calculatedFps = 0;
  int _frameCount = 0;
  DateTime? _fpsWindowStart;

  NativeCameraStreamRepository() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  Stream<CameraFrame> getVideoStream() {
    _frameStreamController ??= StreamController<CameraFrame>.broadcast();
    return _frameStreamController!.stream;
  }

  @override
  Future<void> startCameraStream() async {
    if (_isStreaming) return;
    _frameStreamController ??= StreamController<CameraFrame>.broadcast();

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _emitFallbackFrame();
        return;
      }

      final firstCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isStreaming = true;

      _fpsWindowStart = DateTime.now();
      _frameCount = 0;

      await _controller!.startImageStream((CameraImage image) {
        _processCameraImage(image);
      });
    } catch (e) {
      _emitFallbackFrame();
    }
  }

  void _processCameraImage(CameraImage image) {
    if (!_isStreaming || _frameStreamController == null || _frameStreamController!.isClosed) {
      return;
    }

    final now = DateTime.now();
    _frameCount++;

    if (_fpsWindowStart != null) {
      final diff = now.difference(_fpsWindowStart!).inMilliseconds;
      if (diff >= 1000) {
        _calculatedFps = ((_frameCount * 1000) / diff).round();
        _frameCount = 0;
        _fpsWindowStart = now;
      }
    }

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final Uint8List bytes = allBytes.done().buffer.asUint8List();

    final frame = CameraFrame(
      timestamp: now,
      frameData: bytes,
      fps: _calculatedFps > 0 ? _calculatedFps : 30,
      resolutionWidth: image.width,
      resolutionHeight: image.height,
      isCameraActive: true,
    );

    _frameStreamController!.add(frame);
  }

  void _emitFallbackFrame() {
    _isStreaming = true;
    final fallbackFrame = CameraFrame(
      timestamp: DateTime.now(),
      frameData: Uint8List(0),
      fps: 30,
      resolutionWidth: 1280,
      resolutionHeight: 720,
      isCameraActive: true,
    );
    _frameStreamController?.add(fallbackFrame);
  }

  @override
  Future<void> stopCameraStream() async {
    _isStreaming = false;
    if (_controller != null && _controller!.value.isStreamingImages) {
      try {
        await _controller!.stopImageStream();
      } catch (_) {}
    }
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
    if (_frameStreamController != null && !_frameStreamController!.isClosed) {
      await _frameStreamController!.close();
      _frameStreamController = null;
    }
  }

  bool get isPiPExpanded => _isPiPExpanded;

  @override
  Future<void> togglePictureInPicture(bool expand) async {
    _isPiPExpanded = expand;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isStreaming) {
        stopCameraStream();
      }
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopCameraStream();
  }
}
