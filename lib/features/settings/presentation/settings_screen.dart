import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listyb/l10n/app_localizations.dart';
import '../../../di/settings_providers.dart';
import '../../../core/settings/settings_repository.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(settingsStateProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commonSettings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.settingsTheme,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<AppThemePref>(
            segments: [
              ButtonSegment(
                value: AppThemePref.system,
                label: Text(l10n.settingsThemeSystem),
                icon: const Icon(Icons.settings),
              ),
              ButtonSegment(
                value: AppThemePref.light,
                label: Text(l10n.settingsThemeLight),
                icon: const Icon(Icons.light_mode),
              ),
              ButtonSegment(
                value: AppThemePref.dark,
                label: Text(l10n.settingsThemeDark),
                icon: const Icon(Icons.dark_mode),
              ),
            ],
            selected: {state.themePref},
            onSelectionChanged: (newSelection) {
              controller.setTheme(newSelection.first);
            },
          ),
          const Divider(height: 32),
          Text(
            l10n.settingsLanguage,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<AppLanguage>(
            segments: [
              ButtonSegment(
                value: AppLanguage.system,
                label: Text(l10n.settingsLanguageSystem),
                icon: const Icon(Icons.language),
              ),
              ButtonSegment(
                value: AppLanguage.ru,
                label: const Text('Русский'),
                icon: const Icon(Icons.translate),
              ),
              ButtonSegment(
                value: AppLanguage.en,
                label: const Text('English'),
                icon: const Icon(Icons.translate),
              ),
            ],
            selected: {state.language},
            onSelectionChanged: (newSelection) {
              controller.setLanguage(newSelection.first);
            },
          ),
        ],
      ),
    );
  }
}
