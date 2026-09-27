import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hand_tech/data/models/translation_frame.dart';
import 'package:hand_tech/data/repositories/translation_history_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SharedPreferencesTranslationHistoryRepository Unit Tests', () {
    late SharedPreferencesTranslationHistoryRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repository = SharedPreferencesTranslationHistoryRepository(prefs: prefs);
    });

    test('getHistory returns empty list initially', () async {
      final history = await repository.getHistory();
      expect(history, isEmpty);
    });

    test('saveTranslationFrame persists frame to offline storage', () async {
      final frame = TranslationFrame(
        timestamp: DateTime(2026, 9, 27, 18, 0, 0),
        recognizedText: 'Hello Hand Tech',
        confidenceScore: 0.98,
        isFinal: true,
        detectedSignLanguage: 'LSF',
      );

      await repository.saveTranslationFrame(frame);

      final history = await repository.getHistory();
      expect(history.length, equals(1));
      expect(history.first.recognizedText, equals('Hello Hand Tech'));
      expect(history.first.confidenceScore, equals(0.98));
      expect(history.first.detectedSignLanguage, equals('LSF'));
    });

    test('saveSession appends multiple frames and clearHistory wipes stored frames', () async {
      final frames = [
        TranslationFrame(
          timestamp: DateTime(2026, 9, 27, 18, 1, 0),
          recognizedText: 'Frame 1',
          confidenceScore: 0.95,
          isFinal: false,
          detectedSignLanguage: 'ASL',
        ),
        TranslationFrame(
          timestamp: DateTime(2026, 9, 27, 18, 2, 0),
          recognizedText: 'Frame 2',
          confidenceScore: 0.99,
          isFinal: true,
          detectedSignLanguage: 'ASL',
        ),
      ];

      await repository.saveSession(frames);

      final history = await repository.getHistory();
      expect(history.length, equals(2));

      await repository.clearHistory();

      final clearedHistory = await repository.getHistory();
      expect(clearedHistory, isEmpty);
    });
  });
}
