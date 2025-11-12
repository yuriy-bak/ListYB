import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';
import 'deeplinks.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
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
    return MaterialApp.router(
      title: 'ListYB',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: appRouter,
    );
  }
}
