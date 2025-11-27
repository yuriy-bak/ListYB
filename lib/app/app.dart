import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';
import 'deeplinks.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:listyb/l10n/app_localizations.dart';
import '../di/settings_providers.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  late final DeepLinkCoordinator _deeplinks = DeepLinkCoordinator(
    router: appRouter,
  );

  @override
  void initState() {
    super.initState();
    _deeplinks.init();
  }

  @override
  void dispose() {
    _deeplinks.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsStateProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: appRouter,
      locale: settings.locale,
      supportedLocales: const [Locale('en'), Locale('ru')],
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
