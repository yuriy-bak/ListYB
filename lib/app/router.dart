import 'package:go_router/go_router.dart';

import '../features/lists/presentation/lists_screen.dart';
import '../features/lists/presentation/list_details_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/about/presentation/about_screen.dart';

/// Оставляю фабрику для совместимости с твоим main.dart,
/// где вызывается `createAppRouter()`.
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
        final idStr = state.pathParameters['id'] ?? '';
        // Т.к. экран ожидает int — парсим. Невалидное -> 0 (или можно показать ошибку).
        final id = int.tryParse(idStr) ?? 0;
        return ListDetailsScreen(listId: id);
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
