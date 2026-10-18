import 'package:flutter_test/flutter_test.dart';
import 'package:handtech/services/app_preferences_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppPreferencesService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = AppPreferencesService();
  });

  test('uses French and light theme by default', () async {
    final preferences = await service.load();

    expect(preferences.isEnglish, isFalse);
    expect(preferences.isDarkTheme, isFalse);
  });

  test('restores saved language and theme preferences', () async {
    await service.saveLanguage(true);
    await service.saveTheme(true);

    final preferences = await service.load();

    expect(preferences.isEnglish, isTrue);
    expect(preferences.isDarkTheme, isTrue);
  });

  test('updates language and theme independently', () async {
    await service.saveLanguage(true);
    await service.saveTheme(false);

    var preferences = await service.load();
    expect(preferences.isEnglish, isTrue);
    expect(preferences.isDarkTheme, isFalse);

    await service.saveLanguage(false);
    await service.saveTheme(true);
    preferences = await service.load();
    expect(preferences.isEnglish, isFalse);
    expect(preferences.isDarkTheme, isTrue);
  });
}
