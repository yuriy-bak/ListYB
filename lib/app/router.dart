import 'package:go_router/go_router.dart';

import '../features/lists/presentation/lists_screen.dart';
import '../features/lists/presentation/list_details_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/about/presentation/about_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (_, __) => const ListsScreen(),
      routes: [
        GoRoute(
          path: 'list/:id',
          name: 'listDetails',
          builder: (context, state) =>
              ListDetailsScreen(listId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: 'settings',
          name: 'settings',
          builder: (_, __) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'about',
          name: 'about',
          builder: (_, __) => const AboutScreen(),
        ),
      ],
    ),
  ],
  debugLogDiagnostics: true,
);
