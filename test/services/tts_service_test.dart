import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:hand_tech/data/services/tts_service.dart';

class MockFlutterTts extends Mock implements FlutterTts {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterTtsService Unit Tests', () {
    late MockFlutterTts mockTts;
    late FlutterTtsService service;

    setUp(() {
      mockTts = MockFlutterTts();
      service = FlutterTtsService(flutterTts: mockTts);
    });

    test('speak delegates to FlutterTts when text is non-empty', () async {
      when(() => mockTts.speak('Hello World')).thenAnswer((_) async => 1);

      await service.speak('Hello World');

      verify(() => mockTts.speak('Hello World')).called(1);
    });

    test('speak ignores empty strings', () async {
      await service.speak('   ');

      verifyNever(() => mockTts.speak(any()));
    });

    test('stop delegates to FlutterTts', () async {
      when(() => mockTts.stop()).thenAnswer((_) async => 1);

      await service.stop();

      verify(() => mockTts.stop()).called(1);
    });

    test('setLanguage delegates to FlutterTts', () async {
      when(() => mockTts.setLanguage('fr-FR')).thenAnswer((_) async => 1);

      await service.setLanguage('fr-FR');

      verify(() => mockTts.setLanguage('fr-FR')).called(1);
    });

    test('setSpeechRate delegates to FlutterTts', () async {
      when(() => mockTts.setSpeechRate(0.5)).thenAnswer((_) async => 1);

      await service.setSpeechRate(0.5);

      verify(() => mockTts.setSpeechRate(0.5)).called(1);
    });
  });
}
