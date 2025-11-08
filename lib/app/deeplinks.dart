import 'package:flutter/widgets.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';
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
    // Обязательно навигируем ПОСЛЕ первого кадра, когда Router уже в дереве.
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handle(initial);
      });
    }
  }

  /// Отписка и очистка.
  void dispose() {
    _sub?.cancel();
  }

  void _handle(Uri uri) {
    final path = _mapUriToPath(uri);
    if (path == null) return;

    if (_lastPath == path) return; // защита от дублей из плагина/интента
    _lastPath = path;

    // Уходим в микрозадачу, чтобы не конфликтовать с callback’ами платформы.
    Future.microtask(() => router.go(path));
  }

  /// Преобразование входящего `Uri` в путь `go_router`.
  ///
  /// Поддержка:
  /// - `listyb://home`     → `/`
  /// - `listyb://list/:id` → `/list/:id`
  /// - `listyb://list/:id/add` → `/list/:id` (квик-экран R1 открываем как список)
  ///
  /// И альтернативы с host=app.
  String? _mapUriToPath(Uri? uri) {
    if (uri == null) return null;

    final cmd = parseDeepLink(uri);
    if (cmd == null) return null;

    if (cmd is OpenHomeCmd) return '/';
    if (cmd is OpenListCmd) return '/list/${cmd.listId}';
    if (cmd is QuickAddCmd) return '/list/${cmd.listId}';
    // В R1 нет отдельного маршрута QuickEdit — игнорируем
    if (cmd is QuickEditCmd) return null;

    return null;
  }
}
