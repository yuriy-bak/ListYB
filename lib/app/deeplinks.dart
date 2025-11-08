import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';

/// Координатор диплинков: единая обработка cold + hot через app_links.
class DeepLinkCoordinator {
  DeepLinkCoordinator({
    required this.router,
    AppLinks? appLinks,
  }) : _appLinks = appLinks ?? AppLinks();

  final GoRouter router;
  final AppLinks _appLinks;

  StreamSubscription<Uri>? _sub;
  String? _lastPath;

  /// Инициализация: подписываемся на поток сразу.
  /// По документации app_links, поток выдаёт и начальную ссылку, если инстанс
  /// создан достаточно рано. Поэтому отдельный getInitial... не нужен.
  Future<void> init() async {
    _sub = _appLinks.uriLinkStream.listen(
      _handle,
      onError: (_) {},
      cancelOnError: false,
    );
  }

  void _handle(Uri? uri) {
    final path = _mapUriToPath(uri);
    if (path == null) return;

    final current = _currentLocation();
    // Защита от повторной навигации
    if (_lastPath == path || current == path) return;
    _lastPath = path;

    // Перекладываем текущее местоположение: никаких лишних push.
    router.go(path);
  }

  String _currentLocation() {
    try {
      return router.routerDelegate.currentConfiguration.uri.toString();
    } catch (_) {
      return '';
    }
  }

  String? _mapUriToPath(Uri? uri) {
    if (uri == null) return null;
    if (uri.scheme.toLowerCase() != 'listyb') return null;

    final host = uri.host.toLowerCase();
    switch (host) {
      case 'home':
        return '/';
      case 'list':
        if (uri.pathSegments.isEmpty) return null;
        final id = uri.pathSegments.first;
        final valid = RegExp(r'^[A-Za-z0-9_-]+$'); // задел на будущее
        if (!valid.hasMatch(id)) return null;
        return '/list/$id';
      default:
        return null;
    }
  }

  Future<void> dispose() async => _sub?.cancel();
}