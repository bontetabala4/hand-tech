import 'package:flutter_test/flutter_test.dart';
import 'package:handtech/services/translation_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TranslationHistoryService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = TranslationHistoryService();
  });

  test('stores translations separately for each signed-in account', () async {
    final entry = TranslationHistoryEntry(
      text: 'Bonjour',
      translatedText: 'Hello',
      sourceLanguage: 'fr',
      targetLanguage: 'en',
      createdAt: DateTime.utc(2026, 10, 12),
    );

    await service.add('alice@example.com', entry);

    expect(
      (await service.load('alice@example.com')).single.toJson(),
      entry.toJson(),
    );
    expect(await service.load('bob@example.com'), isEmpty);
  });

  test('keeps only the newest 100 history entries', () async {
    for (var index = 0; index < 105; index++) {
      await service.add(
        'alice@example.com',
        TranslationHistoryEntry(
          text: 'Text $index',
          translatedText: 'Translation $index',
          sourceLanguage: 'fr',
          targetLanguage: 'en',
          createdAt: DateTime.utc(2026, 10, 12).add(Duration(seconds: index)),
        ),
      );
    }

    final history = await service.load('alice@example.com');

    expect(history, hasLength(100));
    expect(history.first.text, 'Text 104');
    expect(history.last.text, 'Text 5');
  });

  test(
    'clears the history for one account without affecting another',
    () async {
      final entry = TranslationHistoryEntry(
        text: 'Bonjour',
        translatedText: 'Hello',
        sourceLanguage: 'fr',
        targetLanguage: 'en',
        createdAt: DateTime.utc(2026, 10, 12),
      );
      await service.add('alice@example.com', entry);
      await service.add('bob@example.com', entry);

      await service.clear('alice@example.com');

      expect(await service.load('alice@example.com'), isEmpty);
      expect(
        (await service.load('bob@example.com')).single.toJson(),
        entry.toJson(),
      );
    },
  );
}
