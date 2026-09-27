import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/translation_repository.dart';
import '../data/repositories/mock_translation_repository.dart';
import '../data/repositories/websocket_translation_repository.dart';
import '../data/repositories/translation_history_repository.dart';
import '../data/services/haptic_feedback_service.dart';
import '../data/services/tts_service.dart';
import 'hardware_providers.dart';

final translationRepositoryProvider = Provider<TranslationRepository>((ref) {
  return MockTranslationRepository();
});

final webSocketTranslationRepositoryProvider = Provider<WebSocketTranslationRepository>((ref) {
  return WebSocketTranslationRepository();
});

final translationHistoryRepositoryProvider = Provider<TranslationHistoryRepository>((ref) {
  return SharedPreferencesTranslationHistoryRepository();
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
  final HapticFeedbackService? _hapticService;
  final TtsService? _ttsService;
  StreamSubscription? _subscription;

  TranslationNotifier(
    this._repository, {
    HapticFeedbackService? hapticService,
    TtsService? ttsService,
  })  : _hapticService = hapticService,
        _ttsService = ttsService,
        super(TranslationState());

  void toggleTranslation() {
    if (state.status == TranslationStatus.listening || state.status == TranslationStatus.translating) {
      pauseTranslation();
    } else {
      startTranslation();
    }
  }

  Future<void> speakCurrentText() async {
    if (state.liveText.isNotEmpty) {
      await _ttsService?.speak(state.liveText);
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
          if (frame.confidenceScore < 0.7) {
            _hapticService?.warningNotification();
          }

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
          _hapticService?.errorNotification();
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
      _hapticService?.errorNotification();
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
    _ttsService?.stop();
    super.dispose();
  }
}

final translationProvider = StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
  final repo = ref.watch(translationRepositoryProvider);
  final haptics = ref.watch(hapticServiceProvider);
  final tts = ref.watch(ttsServiceProvider);
  return TranslationNotifier(repo, hapticService: haptics, ttsService: tts);
});
