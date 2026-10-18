import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  SpeechService() : _tts = FlutterTts();

  final FlutterTts _tts;

  Future<void> speak({
    required String text,
    required String languageCode,
    required double rate,
  }) async {
    await _tts.awaitSpeakCompletion(true);
    await _tts.setLanguage(languageCode);
    await _tts.setSpeechRate(rate);
    await _tts.setVolume(1);
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
