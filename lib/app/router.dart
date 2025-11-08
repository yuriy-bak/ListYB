import 'package:go_router/go_router.dart';

import '../features/lists/presentation/lists_screen.dart';
import '../features/lists/presentation/list_details_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/about/presentation/about_screen.dart';

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
        final idStr = state.pathParameters['id'] ?? '';
        // Экран ожидает строковый listId — пробрасываем как есть.
        return ListDetailsScreen(listId: idStr);
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
