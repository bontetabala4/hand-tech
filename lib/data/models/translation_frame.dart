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

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'recognizedText': recognizedText,
      'confidenceScore': confidenceScore,
      'isFinal': isFinal,
      'detectedSignLanguage': detectedSignLanguage,
    };
  }

  factory TranslationFrame.fromJson(Map<String, dynamic> json) {
    return TranslationFrame(
      timestamp: DateTime.parse(json['timestamp'] as String),
      recognizedText: json['recognizedText'] as String,
      confidenceScore: (json['confidenceScore'] as num).toDouble(),
      isFinal: json['isFinal'] as bool,
      detectedSignLanguage: json['detectedSignLanguage'] as String,
    );
  }
}
