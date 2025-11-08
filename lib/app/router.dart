import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/lists/presentation/lists_screen.dart';
import '../features/lists/presentation/list_details_screen.dart';
import '../features/quick_screens/quick_add.dart';
import '../features/quick_screens/quick_edit.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/about/presentation/about_screen.dart';

/// Локальный typedef, эквивалентный "Reader" из Riverpod.
/// Это устраняет ошибку "Undefined class 'Reader'".
typedef ReaderFn = T Function<T>(ProviderListenable<T> provider);

/// Для совместимости с твоим main.dart оставляю фабрику.
GoRouter createAppRouter() => appRouter;

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const ListsScreen(),
    ),
    GoRoute(
      path: '/list/:id',
      name: 'list',
      builder: (context, state) {
        final id = int.tryParse(state.pathParameters['id'] ?? '');
        if (id == null) return const ListsScreen();
        return ListDetailsScreen(listId: id);
      },
    ),
    GoRoute(
      path: 'quick_add',
      name: 'quickAdd',
      builder: (context, state) {
        final listId = int.tryParse(state.uri.queryParameters['list'] ?? '');
        if (listId == null) return const ListsScreen();
        return QuickAddScreen(listId: listId);
      },
    ),
    GoRoute(
      path: 'item/:id/edit',
      name: 'editItem',
      builder: (context, state) {
        final itemId = int.tryParse(state.pathParameters['id'] ?? '');
        if (itemId == null) return const ListsScreen();
        return QuickEditScreen(itemId: itemId);
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/about',
      name: 'about',
      builder: (context, state) => const AboutScreen(),
    ),
  ],
  debugLogDiagnostics: true,
);
