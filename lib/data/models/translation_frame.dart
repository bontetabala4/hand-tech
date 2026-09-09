class TranslationFrame {
  final DateTime timestamp;
  final String recognizedText;
  final double confidenceScore;
  final bool isFinal;
  final String detectedSignLanguage;

  const TranslationFrame({
    required this.timestamp,
    required this.recognizedText,
    required this.confidenceScore,
    required this.isFinal,
    required this.detectedSignLanguage,
  });
}
