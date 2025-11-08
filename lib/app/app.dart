import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

/// Корневой виджет приложения.
/// Здесь важно: в createAppRouter передаём `ref.read`, а не сам `ref`,
/// потому что сигнатура ожидает ReaderFn (typedef в router.dart).
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = createAppRouter(ref.read);
    return MaterialApp.router(title: 'ListYB', routerConfig: router);
  }
}
