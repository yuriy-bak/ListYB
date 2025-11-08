import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/lists/presentation/lists_screen.dart';
import '../features/lists/presentation/list_details_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/about/presentation/about_screen.dart';
import '../features/quick_screens/quick_add.dart';
import '../features/quick_screens/quick_edit.dart';

import 'router_refresh.dart';
import 'package:listyb/di/usecase_providers.dart';

/// Локальный typedef, эквивалентный "Reader" из Riverpod.
/// Это устраняет ошибку "Undefined class 'Reader'".
typedef ReaderFn = T Function<T>(ProviderListenable<T> provider);

/// Создание GoRouter без ref.watch (чтобы можно было вызывать из initState).
GoRouter createAppRouter(ReaderFn read) {
  final watchLists = read(watchListsUcProvider);
  final refreshStream = watchLists();
  final refreshListenable = GoRouterRefreshStream(refreshStream);

  return GoRouter(
    refreshListenable: refreshListenable,
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const ListsScreen(),
        routes: [
          GoRoute(
            path: 'list/:id',
            name: 'listDetails',
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
              final listId = int.tryParse(
                state.uri.queryParameters['list'] ?? '',
              );
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
            path: 'settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'about',
            name: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
        ],
      ),
    ],
    debugLogDiagnostics: true,
  );
}
