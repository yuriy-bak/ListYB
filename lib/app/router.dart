import 'package:go_router/go_router.dart';
import '../features/lists/presentation/lists_screen.dart';
import '../features/lists/presentation/list_details_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/about/presentation/about_screen.dart';
// понадобятся команды парсера диплинков
import 'deeplink_parser.dart';

GoRouter createAppRouter() => appRouter;

/// Преобразуем любые входящие URI со схемой listyb://… в нормальные app-пути.
String? _mapListybToPath(Uri uri) {
  final cmd = parseDeepLink(uri);
  if (cmd == null) return null;
  if (cmd is OpenHomeCmd) return '/';
  if (cmd is OpenListCmd) return '/list/${cmd.listId}';
  if (cmd is QuickAddCmd) return '/list/${cmd.listId}?qa=1';
  // QuickEdit в R1 не поддерживаем
  if (cmd is QuickEditCmd) return null;
  return null;
}

bool _asBool(String? v) {
  if (v == null) return false;
  switch (v.toLowerCase()) {
    case '1':
    case 'true':
    case 'yes':
    case 'y':
      return true;
    default:
      return false;
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  // Глобальная нормализация: если в go_router попал listyb://..., конвертируем.
  redirect: (context, state) {
    final uri = state.uri;
    // 1) Полные URI listyb://... → нормализуем
    if (uri.scheme == 'listyb') {
      final mapped = _mapListybToPath(uri);
      // Если распарсить удалось — вернём целевой путь.
      // Если нет — отправим на домашний, чтобы не ронять навигацию.
      return mapped ?? '/';
    }
    // 2) На всякий случай: если кто-то пришёл как /list/:id/add (без схемы),
    // тоже нормализуем до флага быстрого добавления.
    final segs = uri.pathSegments;
    if (segs.length >= 3 && segs[0] == 'list' && segs[2] == 'add') {
      final id = int.tryParse(segs[1]);
      if (id != null) return '/list/$id?qa=1';
    }
    return null; // без изменений
  },
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
        final quickAdd = _asBool(state.uri.queryParameters['qa']);
        final autoClose = _asBool(state.uri.queryParameters['autoclose']);
        final isColdStart = _asBool(state.uri.queryParameters['cold']); // NEW
        return ListDetailsScreen(
          listId: id,
          quickAdd: quickAdd,
          autoCloseWhenDone: autoClose,
          isColdStart: isColdStart, // NEW
        );
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
