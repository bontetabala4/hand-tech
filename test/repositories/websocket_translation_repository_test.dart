import 'package:flutter_test/flutter_test.dart';
import 'package:hand_tech/data/repositories/translation_repository.dart';
import 'package:hand_tech/data/repositories/websocket_translation_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebSocketTranslationRepository Unit Tests', () {
    late WebSocketTranslationRepository repository;

    setUp(() {
      repository = WebSocketTranslationRepository(
        serverUri: Uri.parse('wss://localhost:8080/ws/test'),
      );
    });

    test('should conform to TranslationRepository interface', () {
      expect(repository, isA<TranslationRepository>());
    });

    test('should return a broadcast stream from streamTranslations', () {
      final stream = repository.streamTranslations();
      expect(stream.isBroadcast, isTrue);
    });

    test('should update language and stop translation gracefully', () async {
      await repository.setLanguage('fr');
      await expectLater(repository.stopTranslation(), completes);
    });
  });
}
