import 'dart:async';
import 'dart:math';

import '../models/translation_frame.dart';
import 'translation_repository.dart';

class MockTranslationRepository implements TranslationRepository {
  final _random = Random();
  StreamController<TranslationFrame>? _controller;
  bool _isActive = false;
  String _currentLanguage = 'LSF';

  final List<String> _sentences = [
    "Bonjour comment allez-vous aujourd'hui ?",
    "La traduction en temps réel est activée.",
    "J'utilise la langue des signes française.",
    "Le système fonctionne parfaitement.",
  ];

  @override
  Stream<TranslationFrame> streamTranslations() {
    _controller ??= StreamController<TranslationFrame>.broadcast();
    return _controller!.stream;
  }

  @override
  Future<void> startTranslation() async {
    if (_isActive) return;
    _isActive = true;
    _simulateTranslationStream();
  }

  @override
  Future<void> stopTranslation() async {
    _isActive = false;
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
  }

  void _simulateTranslationStream() async {
    while (_isActive) {
      await Future.delayed(Duration(seconds: _random.nextInt(3) + 2));
      if (!_isActive) break;

      final sentence = _sentences[_random.nextInt(_sentences.length)];
      final words = sentence.split(' ');
      String currentText = "";

      for (int i = 0; i < words.length; i++) {
        if (!_isActive) break;
        
        currentText += (i == 0 ? "" : " ") + words[i];
        final isFinal = i == words.length - 1;
        
        // Simulate variable confidence. Final is always high. Non-final is between 0.5 and 0.9.
        final confidence = isFinal ? 0.95 : (_random.nextDouble() * 0.4 + 0.5); 

        _controller?.add(TranslationFrame(
          timestamp: DateTime.now(),
          recognizedText: currentText,
          confidenceScore: confidence,
          isFinal: isFinal,
          detectedSignLanguage: _currentLanguage,
        ));

        // Simulate varying token gap network latency
        final delayMs = _random.nextInt(400) + 150;
        await Future.delayed(Duration(milliseconds: delayMs));
      }
    }
  }
}
