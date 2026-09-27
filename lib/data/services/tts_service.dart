import 'package:flutter_tts/flutter_tts.dart';

abstract class TtsService {
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> setLanguage(String langCode);
  Future<void> setSpeechRate(double rate);
}

class FlutterTtsService implements TtsService {
  final FlutterTts _flutterTts;

  FlutterTtsService({FlutterTts? flutterTts})
      : _flutterTts = flutterTts ?? FlutterTts();

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await _flutterTts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  @override
  Future<void> setLanguage(String langCode) async {
    await _flutterTts.setLanguage(langCode);
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate);
  }
}
