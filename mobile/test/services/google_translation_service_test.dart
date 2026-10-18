import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:handtech/services/google_translation_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  });

  tearDownAll(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('sends LibreTranslate fields and returns the translated text', () async {
    final client = MockClient((request) async {
      expect(request.method, 'POST');
      expect(request.url, Uri.parse('https://translate.example/translate'));
      expect(jsonDecode(request.body), {
        'q': 'Bonjour',
        'source': 'fr',
        'target': 'en',
        'format': 'text',
      });
      return http.Response(
        jsonEncode({'translatedText': 'Hello'}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final service = GoogleTranslationService(
      client: client,
      translationApiUrl: 'https://translate.example/translate',
    );
    addTearDown(service.dispose);

    final result = await service.translate(
      text: ' Bonjour ',
      sourceLanguage: TranslateLanguage.french,
      targetLanguage: TranslateLanguage.english,
    );

    expect(result, 'Hello');
  });

  test('reports an HTTP error response explicitly', () async {
    final service = GoogleTranslationService(
      client: MockClient((_) async => http.Response('unavailable', 503)),
      translationApiUrl: 'https://translate.example/translate',
    );
    addTearDown(service.dispose);

    await expectLater(
      service.translate(
        text: 'Bonjour',
        sourceLanguage: TranslateLanguage.french,
        targetLanguage: TranslateLanguage.english,
      ),
      throwsA(isA<http.ClientException>()),
    );
  });

  test('rejects a malformed response without a translatedText field', () async {
    final service = GoogleTranslationService(
      client: MockClient(
        (_) async => http.Response(jsonEncode({'result': 'Hello'}), 200),
      ),
      translationApiUrl: 'https://translate.example/translate',
    );
    addTearDown(service.dispose);

    await expectLater(
      service.translate(
        text: 'Bonjour',
        sourceLanguage: TranslateLanguage.french,
        targetLanguage: TranslateLanguage.english,
      ),
      throwsFormatException,
    );
  });

  test('reports an unconfigured remote translator', () async {
    final service = GoogleTranslationService(
      client: MockClient((_) async => http.Response('', 500)),
    );
    addTearDown(service.dispose);

    await expectLater(
      service.translate(
        text: 'Bonjour',
        sourceLanguage: TranslateLanguage.french,
        targetLanguage: TranslateLanguage.english,
      ),
      throwsUnsupportedError,
    );
  });
}
