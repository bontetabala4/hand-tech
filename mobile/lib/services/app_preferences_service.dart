import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  const AppPreferences({this.isEnglish = false, this.isDarkTheme = false});

  final bool isEnglish;
  final bool isDarkTheme;
}

class AppPreferencesService {
  static const _languageKey = 'app_is_english';
  static const _darkThemeKey = 'app_is_dark_theme';

  Future<AppPreferences> load() async {
    final preferences = await SharedPreferences.getInstance();
    return AppPreferences(
      isEnglish: preferences.getBool(_languageKey) ?? false,
      isDarkTheme: preferences.getBool(_darkThemeKey) ?? false,
    );
  }

  Future<void> saveLanguage(bool isEnglish) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setBool(_languageKey, isEnglish)) {
      throw StateError('Could not save the application language.');
    }
  }

  Future<void> saveTheme(bool isDarkTheme) async {
    final preferences = await SharedPreferences.getInstance();
    if (!await preferences.setBool(_darkThemeKey, isDarkTheme)) {
      throw StateError('Could not save the application theme.');
    }
  }
}
