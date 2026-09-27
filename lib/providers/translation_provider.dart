import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/translation_repository.dart';
import '../data/repositories/mock_translation_repository.dart';
import '../data/repositories/websocket_translation_repository.dart';

final translationRepositoryProvider = Provider<TranslationRepository>((ref) {
  return MockTranslationRepository();
});

final webSocketTranslationRepositoryProvider = Provider<WebSocketTranslationRepository>((ref) {
  return WebSocketTranslationRepository();
});

enum TranslationStatus {
  idle,
  listening,
  translating,
  paused,
  error,
}

class TranslationState {
  final TranslationStatus status;
  final String liveText;
  final double lastConfidence;
  final bool isFinal;
  final String? errorMessage;

  TranslationState({
    this.status = TranslationStatus.idle,
    this.liveText = "",
    this.lastConfidence = 1.0,
    this.isFinal = true,
    this.errorMessage,
  });

  TranslationState copyWith({
    TranslationStatus? status,
    String? liveText,
    double? lastConfidence,
    bool? isFinal,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TranslationState(
      status: status ?? this.status,
      liveText: liveText ?? this.liveText,
      lastConfidence: lastConfidence ?? this.lastConfidence,
      isFinal: isFinal ?? this.isFinal,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class TranslationNotifier extends StateNotifier<TranslationState> {
  final TranslationRepository _repository;
  StreamSubscription? _subscription;

  TranslationNotifier(this._repository) : super(TranslationState());

  void toggleTranslation() {
    if (state.status == TranslationStatus.listening || state.status == TranslationStatus.translating) {
      pauseTranslation();
    } else {
      startTranslation();
    }
  }

  Future<void> startTranslation() async {
    state = state.copyWith(
      status: TranslationStatus.listening,
      liveText: "", // Clear buffer on fresh start
      lastConfidence: 1.0,
      isFinal: true,
      clearError: true,
    );

    try {
      await _repository.startTranslation();
      _subscription?.cancel();
      _subscription = _repository.streamTranslations().listen(
        (frame) {
          state = state.copyWith(
            status: TranslationStatus.translating,
            liveText: frame.recognizedText,
            lastConfidence: frame.confidenceScore,
            isFinal: frame.isFinal,
          );
          
          if (frame.isFinal) {
             Future.delayed(const Duration(milliseconds: 500), () {
               if (mounted && state.status == TranslationStatus.translating) {
                 state = state.copyWith(status: TranslationStatus.listening);
               }
             });
          }
        },
        onError: (error) {
          state = state.copyWith(
            status: TranslationStatus.error,
            errorMessage: "Connection error. Reconnecting...",
          );
          _handleReconnect();
        },
        onDone: () {
          pauseTranslation();
        }
      );
    } catch (e) {
      state = state.copyWith(
        status: TranslationStatus.error,
        errorMessage: "Failed to start translation.",
      );
    }
  }

  void _handleReconnect() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && state.status == TranslationStatus.error) {
        startTranslation();
      }
    });
  }

  Future<void> pauseTranslation() async {
    await _repository.stopTranslation();
    _subscription?.cancel();
    state = state.copyWith(
      status: TranslationStatus.paused,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _repository.stopTranslation();
    super.dispose();
  }
}

final translationProvider = StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
  final repo = ref.watch(translationRepositoryProvider);
  return TranslationNotifier(repo);
});
