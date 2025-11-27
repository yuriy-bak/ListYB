import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/settings/settings_repository.dart';
import '../core/settings/settings_controller.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(),
);

final settingsControllerProvider =
    StateNotifierProvider<SettingsController, SettingsState>(
      (ref) => SettingsController(ref.watch(settingsRepositoryProvider)),
    );

/// Удобный alias (если хочется короткое имя в виджетах)
final settingsStateProvider = settingsControllerProvider;
