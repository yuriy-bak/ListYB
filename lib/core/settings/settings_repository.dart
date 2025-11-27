import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { system, ru, en }

enum AppThemePref { system, light, dark }

class SettingsRepository {
  static const _keyTheme = 'settings.themeMode';
  static const _keyLang = 'settings.language';

  Future<(AppThemePref, AppLanguage)> load() async {
    final sp = await SharedPreferences.getInstance();
    final themeStr = sp.getString(_keyTheme) ?? 'system';
    final langStr = sp.getString(_keyLang) ?? 'system';
    return (_parseTheme(themeStr), _parseLang(langStr));
  }

  Future<void> setTheme(AppThemePref theme) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_keyTheme, _themeToStr(theme));
  }

  Future<void> setLanguage(AppLanguage lang) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_keyLang, _langToStr(lang));
  }

  static AppThemePref _parseTheme(String v) {
    switch (v) {
      case 'light':
        return AppThemePref.light;
      case 'dark':
        return AppThemePref.dark;
      default:
        return AppThemePref.system;
    }
  }

  static AppLanguage _parseLang(String v) {
    switch (v) {
      case 'ru':
        return AppLanguage.ru;
      case 'en':
        return AppLanguage.en;
      default:
        return AppLanguage.system;
    }
  }

  static String _themeToStr(AppThemePref v) => switch (v) {
    AppThemePref.light => 'light',
    AppThemePref.dark => 'dark',
    AppThemePref.system => 'system',
  };

  static String _langToStr(AppLanguage v) => switch (v) {
    AppLanguage.ru => 'ru',
    AppLanguage.en => 'en',
    AppLanguage.system => 'system',
  };
}
