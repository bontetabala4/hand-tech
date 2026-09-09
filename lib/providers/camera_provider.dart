import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/camera_stream_repository.dart';
import '../data/repositories/mock_camera_stream_repository.dart';

final cameraRepositoryProvider = Provider<CameraStreamRepository>((ref) {
  return MockCameraStreamRepository();
});

enum CameraStatus {
  disabled,
  streaming,
  paused,
  error,
}

class CameraState {
  final CameraStatus status;
  final bool isExpanded;
  final int currentFps;

  CameraState({
    this.status = CameraStatus.disabled,
    this.isExpanded = false,
    this.currentFps = 0,
  });

  CameraState copyWith({
    CameraStatus? status,
    bool? isExpanded,
    int? currentFps,
  }) {
    return CameraState(
      status: status ?? this.status,
      isExpanded: isExpanded ?? this.isExpanded,
      currentFps: currentFps ?? this.currentFps,
    );
  }
}

class CameraNotifier extends StateNotifier<CameraState> with WidgetsBindingObserver {
  final CameraStreamRepository _repository;
  StreamSubscription? _subscription;

  CameraNotifier(this._repository) : super(CameraState()) {
    WidgetsBinding.instance.addObserver(this);
    startStream();
  }

  Future<void> startStream() async {
    state = state.copyWith(status: CameraStatus.streaming);
    try {
      await _repository.startCameraStream();
      _subscription?.cancel();
      _subscription = _repository.getVideoStream().listen(
        (frame) {
          if (mounted && state.status == CameraStatus.streaming) {
            state = state.copyWith(currentFps: frame.fps);
          }
        },
        onError: (error) {
          state = state.copyWith(status: CameraStatus.error);
        },
      );
    } catch (e) {
      state = state.copyWith(status: CameraStatus.error);
    }
  }

  Future<void> stopStream() async {
    await _repository.stopCameraStream();
    _subscription?.cancel();
    state = state.copyWith(status: CameraStatus.disabled, currentFps: 0);
  }

  Future<void> pauseStream() async {
    await _repository.stopCameraStream(); 
    state = state.copyWith(status: CameraStatus.paused, currentFps: 0);
  }

  void togglePiP() {
    final expand = !state.isExpanded;
    state = state.copyWith(isExpanded: expand);
    _repository.togglePictureInPicture(expand);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.paused || appState == AppLifecycleState.inactive) {
      if (state.status == CameraStatus.streaming) {
        pauseStream();
      }
    } else if (appState == AppLifecycleState.resumed) {
      if (state.status == CameraStatus.paused) {
        startStream();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _repository.stopCameraStream();
    super.dispose();
  }
}

final cameraProvider = StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  final repo = ref.watch(cameraRepositoryProvider);
  final notifier = CameraNotifier(repo);
  // We do not need ref.onDispose to call notifier.dispose() 
  // because StateNotifier disposes itself when the provider is destroyed,
  // which calls our overridden dispose() automatically.
  return notifier;
});
