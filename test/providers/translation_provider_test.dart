import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hand_tech/data/models/translation_frame.dart';
import 'package:hand_tech/data/repositories/translation_repository.dart';
import 'package:hand_tech/data/services/haptic_feedback_service.dart';
import 'package:hand_tech/data/services/tts_service.dart';
import 'package:hand_tech/providers/hardware_providers.dart';
import 'package:hand_tech/providers/translation_provider.dart';

class MockTranslationRepository extends Mock implements TranslationRepository {}

/// No-op haptic service — avoids platform channel in tests.
class _FakeHapticService implements HapticFeedbackService {
  @override Future<void> selectionClick() async {}
  @override Future<void> successNotification() async {}
  @override Future<void> warningNotification() async {}
  @override Future<void> errorNotification() async {}
}

/// No-op TTS service — avoids FlutterTts platform channel in tests.
class _FakeTtsService implements TtsService {
  @override Future<void> speak(String text) async {}
  @override Future<void> stop() async {}
  @override Future<void> setLanguage(String langCode) async {}
  @override Future<void> setSpeechRate(double rate) async {}
}

/// Shared overrides injected into every container in this file.
List<Override> _baseOverrides(MockTranslationRepository repo) => [
      translationRepositoryProvider.overrideWithValue(repo),
      hapticServiceProvider.overrideWithValue(_FakeHapticService()),
      ttsServiceProvider.overrideWithValue(_FakeTtsService()),
    ];

void main() {
  late MockTranslationRepository mockRepository;
  late StreamController<TranslationFrame> streamController;

  setUp(() {
    mockRepository = MockTranslationRepository();
    streamController = StreamController<TranslationFrame>.broadcast();
    when(() => mockRepository.streamTranslations())
        .thenAnswer((_) => streamController.stream);
    when(() => mockRepository.startTranslation())
        .thenAnswer((_) async {});
    when(() => mockRepository.stopTranslation())
        .thenAnswer((_) async {});
  });

  tearDown(() {
    streamController.close();
  });

  group('TranslationNotifier Tests', () {
    test('Initial state is idle', () {
      final container = ProviderContainer(overrides: _baseOverrides(mockRepository));
      addTearDown(container.dispose);

      final state = container.read(translationProvider);
      expect(state.status, TranslationStatus.idle);
      expect(state.liveText, "");
      expect(state.lastConfidence, 1.0);
      expect(state.isFinal, true);
      expect(state.errorMessage, isNull);
    });

    test('Toggling translation starts listening/translating or pauses translation', () async {
      final container = ProviderContainer(overrides: _baseOverrides(mockRepository));
      addTearDown(container.dispose);

      final notifier = container.read(translationProvider.notifier);

      // Idle -> Toggle -> Listening
      notifier.toggleTranslation();
      await pumpEventQueue();

      expect(container.read(translationProvider).status, TranslationStatus.listening);
      verify(() => mockRepository.startTranslation()).called(1);

      // Listening -> Toggle -> Paused
      notifier.toggleTranslation();
      await pumpEventQueue();

      expect(container.read(translationProvider).status, TranslationStatus.paused);
      verify(() => mockRepository.stopTranslation()).called(1);
    });

    test('Text buffer is retained when translation is paused', () async {
      final container = ProviderContainer(overrides: _baseOverrides(mockRepository));
      addTearDown(container.dispose);

      final notifier = container.read(translationProvider.notifier);
      await notifier.startTranslation();

      final frame = TranslationFrame(
        timestamp: DateTime.now(),
        recognizedText: "Retained translation buffer text",
        confidenceScore: 0.95,
        isFinal: false,
        detectedSignLanguage: "ASL",
      );

      streamController.add(frame);
      await pumpEventQueue();

      expect(container.read(translationProvider).liveText, "Retained translation buffer text");

      await notifier.pauseTranslation();

      final state = container.read(translationProvider);
      expect(state.status, TranslationStatus.paused);
      expect(state.liveText, "Retained translation buffer text");
    });

    test('Confidence score updating and frame processing', () async {
      final container = ProviderContainer(overrides: _baseOverrides(mockRepository));
      addTearDown(container.dispose);

      final notifier = container.read(translationProvider.notifier);
      await notifier.startTranslation();

      final frame1 = TranslationFrame(
        timestamp: DateTime.now(),
        recognizedText: "Hello",
        confidenceScore: 0.82,
        isFinal: false,
        detectedSignLanguage: "ASL",
      );

      streamController.add(frame1);
      await pumpEventQueue();

      var state = container.read(translationProvider);
      expect(state.status, TranslationStatus.translating);
      expect(state.liveText, "Hello");
      expect(state.lastConfidence, 0.82);
      expect(state.isFinal, false);

      final frame2 = TranslationFrame(
        timestamp: DateTime.now(),
        recognizedText: "Hello World",
        confidenceScore: 0.98,
        isFinal: true,
        detectedSignLanguage: "ASL",
      );

      streamController.add(frame2);
      await pumpEventQueue();

      state = container.read(translationProvider);
      expect(state.status, TranslationStatus.translating);
      expect(state.liveText, "Hello World");
      expect(state.lastConfidence, 0.98);
      expect(state.isFinal, true);
    });
  });
}
