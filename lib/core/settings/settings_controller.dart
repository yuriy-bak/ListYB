import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_repository.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale? locale; // null -> системный
  final AppLanguage language;
  final AppThemePref themePref;
  const SettingsState({
    required this.themeMode,
    required this.locale,
    required this.language,
    required this.themePref,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
    AppLanguage? language,
    AppThemePref? themePref,
  }) => SettingsState(
    themeMode: themeMode ?? this.themeMode,
    locale: locale,
    language: language ?? this.language,
    themePref: themePref ?? this.themePref,
  );

  static SettingsState initial() => const SettingsState(
    themeMode: ThemeMode.system,
    locale: null,
    language: AppLanguage.system,
    themePref: AppThemePref.system,
  );
}

class SettingsController extends StateNotifier<SettingsState> {
  final SettingsRepository repo;
  SettingsController(this.repo) : super(SettingsState.initial()) {
    _load();
  }

  Future<void> _load() async {
    final (themePref, lang) = await repo.load();
    final locale = _toLocale(lang);
    state = SettingsState(
      themeMode: _toThemeMode(themePref),
      locale: locale,
      language: lang,
      themePref: themePref,
    );
  }

  Future<void> setTheme(AppThemePref pref) async {
    await repo.setTheme(pref);
    state = state.copyWith(themeMode: _toThemeMode(pref), themePref: pref);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    await repo.setLanguage(lang);
    state = state.copyWith(locale: _toLocale(lang), language: lang);
  }

  ThemeMode _toThemeMode(AppThemePref p) => switch (p) {
    AppThemePref.light => ThemeMode.light,
    AppThemePref.dark => ThemeMode.dark,
    AppThemePref.system => ThemeMode.system,
  };

  Locale? _toLocale(AppLanguage l) => switch (l) {
    AppLanguage.ru => const Locale('ru'),
    AppLanguage.en => const Locale('en'),
    AppLanguage.system => null,
  };
}
