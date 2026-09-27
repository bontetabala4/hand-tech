import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation_frame.dart';

abstract class TranslationHistoryRepository {
  Future<void> saveTranslationFrame(TranslationFrame frame);
  Future<void> saveSession(List<TranslationFrame> session);
  Future<List<TranslationFrame>> getHistory();
  Future<void> clearHistory();
}

class SharedPreferencesTranslationHistoryRepository implements TranslationHistoryRepository {
  static const String _historyKey = 'offline_translation_history_frames';

  final SharedPreferences? _prefs;

  SharedPreferencesTranslationHistoryRepository({SharedPreferences? prefs})
      : _prefs = prefs;

  Future<SharedPreferences> get _instance async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  @override
  Future<void> saveTranslationFrame(TranslationFrame frame) async {
    final prefs = await _instance;
    final currentHistory = await getHistory();
    currentHistory.add(frame);

    final jsonList = currentHistory.map((f) => f.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  @override
  Future<void> saveSession(List<TranslationFrame> session) async {
    final prefs = await _instance;
    final currentHistory = await getHistory();
    currentHistory.addAll(session);

    final jsonList = currentHistory.map((f) => f.toJson()).toList();
    await prefs.setString(_historyKey, jsonEncode(jsonList));
  }

  @override
  Future<List<TranslationFrame>> getHistory() async {
    final prefs = await _instance;
    final jsonStr = prefs.getString(_historyKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> decodedList = jsonDecode(jsonStr) as List<dynamic>;
      return decodedList
          .map((item) => TranslationFrame.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> clearHistory() async {
    final prefs = await _instance;
    await prefs.remove(_historyKey);
  }
}
