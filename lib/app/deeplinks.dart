import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

import 'deeplink_parser.dart';

/// Координатор диплинков: единая обработка cold + hot через `app_links`.
class DeepLinkCoordinator {
  DeepLinkCoordinator({required this.router, AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  final GoRouter router;
  final AppLinks _appLinks;

  StreamSubscription<Uri>? _sub;
  String? _lastPath; // защита от повторной навигации

  /// Подписываемся на поток ссылок и обрабатываем начальную.
  Future<void> init() async {
    // Горячие ссылки (когда приложение уже запущено)
    _sub = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (_) {},
      cancelOnError: false,
    );

    // Холодный старт (приложение запущено из диплинка)
    // В актуальных версиях app_links используется getInitialLink().
    // См. https://pub.dev/documentation/app_links/latest/app_links/AppLinks-class.html
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      _handle(initial);
    }
  }

  /// Отписка и очистка.
  void dispose() {
    _sub?.cancel();
  }

  void _handle(Uri uri) {
    final path = _mapUriToPath(uri);
    if (path == null) return;

    // защита от повторной навигации одинаковым путём подряд
    if (_lastPath == path) return;
    _lastPath = path;

    final current = _currentLocation();
    if (current != path) {
      router.go(path);
    }
  }

  /// Текущая локация роутера (безопасно для разных версий go_router).
  String _currentLocation() {
    try {
      return router.routerDelegate.currentConfiguration.uri.toString();
    } catch (_) {
      try {
        // ignore: deprecated_member_use
        return router.routeInformationProvider.value.location;
      } catch (_) {
        return '';
      }
    }
  }

  /// Преобразование входящего `Uri` в путь `go_router`.
  ///
  /// Поддержка:
  /// - `listyb://home` → `/`
  /// - `listyb://list/:id` → `/list/:id`
  /// - `listyb://list/:id/add` → `/list/:id` (квик‑экран можно добавить позже)
  String? _mapUriToPath(Uri? uri) {
    if (uri == null) return null;

    // Предпочтительно используем типобезопасный парсер команд
    final cmd = parseDeepLink(uri);
    if (cmd != null) {
      if (cmd is OpenListCmd) return '/list/${cmd.listId}';
      if (cmd is QuickAddCmd) return '/list/${cmd.listId}';
      // В R1 нет отдельного маршрута QuickEdit — игнорируем
      return null;
    }

    // Back‑compat со старыми ссылками вида listyb://home
    if (uri.scheme.toLowerCase() != 'listyb') return null;
    final host = uri.host.toLowerCase();
    if (host == 'home') return '/';
    return null;
  }
}
