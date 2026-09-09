import '../models/translation_frame.dart';

abstract class TranslationRepository {
  Stream<TranslationFrame> streamTranslations();
  Future<void> startTranslation();
  Future<void> stopTranslation();
  Future<void> setLanguage(String languageCode);
}
