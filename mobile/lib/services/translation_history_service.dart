import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class TranslationHistoryEntry {
  const TranslationHistoryEntry({
    required this.text,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.createdAt,
  });

  final String text;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
    'text': text,
    'translatedText': translatedText,
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'createdAt': createdAt.toIso8601String(),
  };

  static TranslationHistoryEntry? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final text = value['text'];
    final translatedText = value['translatedText'];
    final sourceLanguage = value['sourceLanguage'];
    final targetLanguage = value['targetLanguage'];
    final createdAt = value['createdAt'];
    if (text is! String ||
        translatedText is! String ||
        sourceLanguage is! String ||
        targetLanguage is! String ||
        createdAt is! String) {
      return null;
    }
    final date = DateTime.tryParse(createdAt);
    if (date == null) return null;
    return TranslationHistoryEntry(
      text: text,
      translatedText: translatedText,
      sourceLanguage: sourceLanguage,
      targetLanguage: targetLanguage,
      createdAt: date,
    );
  }
}

class TranslationHistoryService {
  static const _maxEntries = 100;

  String _keyFor(String accountEmail) =>
      'translation_history_${base64Url.encode(utf8.encode(accountEmail.toLowerCase()))}';

  Future<List<TranslationHistoryEntry>> load(String accountEmail) async {
    final preferences = await SharedPreferences.getInstance();
    final data = preferences.getString(_keyFor(accountEmail));
    if (data == null) return const [];
    final Object? decoded;
    try {
      decoded = jsonDecode(data);
    } on FormatException catch (error) {
      throw FormatException('Translation history is corrupted.', error);
    }
    if (decoded is! List) return const [];
    return decoded
        .map(TranslationHistoryEntry.fromJson)
        .whereType<TranslationHistoryEntry>()
        .toList(growable: false);
  }

  Future<void> add(
    String accountEmail,
    TranslationHistoryEntry entry,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final entries = await load(accountEmail);
    final updated = [entry, ...entries].take(_maxEntries).toList();
    final saved = await preferences.setString(
      _keyFor(accountEmail),
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
    if (!saved) {
      throw StateError('Could not save translation history.');
    }
  }

  Future<void> clear(String accountEmail) async {
    final preferences = await SharedPreferences.getInstance();
    final removed = await preferences.remove(_keyFor(accountEmail));
    if (!removed) {
      throw StateError('Could not clear translation history.');
    }
  }
}
