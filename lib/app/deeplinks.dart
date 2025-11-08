import 'package:flutter/widgets.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';

import 'deeplink_parser.dart';

/// Координатор диплинков: cold → go, hot → push.
/// QuickAdd помечаем query-параметрами: qa=1, а для cold — autoclose=1.
class DeepLinkCoordinator {
  DeepLinkCoordinator({required this.router, AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  final GoRouter router;
  final AppLinks _appLinks;

  StreamSubscription<Uri>? _sub;
  String? _lastPath;
  bool _initialProcessed = false;

  Future<void> init() async {
    // Горячие ссылки
    _sub = _appLinks.uriLinkStream.listen(
      _handleHot,
      onError: (_) {},
      cancelOnError: false,
    );

    // Холодный старт
    final initial = await _appLinks.getInitialLink();
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleCold(initial);
        _initialProcessed = true;
      });
    } else {
      _initialProcessed = true;
    }
  }

  void dispose() {
    _sub?.cancel();
  }

  void _handleCold(Uri uri) {
    String? path = _mapUriToPath(uri);
    if (path == null) return;

    // Если это QuickAdd (qa=1) — добавляем autoclose=1
    if (path.contains('qa=1') && !path.contains('autoclose=1')) {
      path = _appendQuery(path, {'autoclose': '1'});
    }

    if (_shouldSkip(path)) return;
    Future.microtask(() => router.go(path!));
  }

  void _handleHot(Uri uri) {
    if (!_initialProcessed) return;

    final path = _mapUriToPath(uri);
    if (path == null) return;
    if (_shouldSkip(path)) return;

    Future.microtask(() => router.push(path));
  }

  String? _mapUriToPath(Uri? uri) {
    if (uri == null) return null;
    final cmd = parseDeepLink(uri);
    if (cmd == null) return null;
    if (cmd is OpenHomeCmd) return '/';
    if (cmd is OpenListCmd) return '/list/${cmd.listId}';
    if (cmd is QuickAddCmd) return '/list/${cmd.listId}?qa=1';
    if (cmd is QuickEditCmd) return null; // R1: не поддерживаем
    return null;
  }

  bool _shouldSkip(String path) {
    if (_lastPath == path) return true; // антидубль по последнему
    _lastPath = path;
    return false;
  }

  String _appendQuery(String path, Map<String, String> qp) {
    final hasQuery = path.contains('?');
    final prefix = hasQuery ? '&' : '?';
    final tail = qp.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');
    return '$path$prefix$tail';
  }
}
