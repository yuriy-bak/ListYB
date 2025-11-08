import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';

import 'app/router.dart';
import 'app/deeplink_parser.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ListYBApp()));
}

class ListYBApp extends ConsumerStatefulWidget {
  const ListYBApp({super.key});

  @override
  ConsumerState<ListYBApp> createState() => _ListYBAppState();
}

class _ListYBAppState extends ConsumerState<ListYBApp> {
  late final AppLinks _appLinks;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();

    // ⬇️ Создаём роутер через ref.read, а не ref.watch!
    _router ??= createAppRouter(ref.read);

    _appLinks = AppLinks();

    // cold start
    _handleInitialLink();

    // runtime (uriLinkStream отдаёт non-null Uri)
    _appLinks.uriLinkStream.listen((uri) {
      if (!mounted) return;
      _handleUri(uri);
    });
  }

  Future<void> _handleInitialLink() async {
    try {
      // актуальный API пакета app_links — getInitialLink()
      final uri = await _appLinks.getInitialLink();
      if (!mounted || uri == null) return;
      _handleUri(uri);
    } catch (_) {
      // ignore
    }
  }

  void _handleUri(Uri uri) {
    final cmd = parseDeepLink(uri);
    if (cmd == null) return;

    final r = _router!;
    switch (cmd) {
      case OpenListCmd(:final listId):
        r.push('/list/$listId');
        break;
      case QuickAddCmd(:final listId):
        r.push('/quick_add?list=$listId');
        break;
      case QuickEditCmd(:final itemId):
        r.push('/item/$itemId/edit');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // На всякий случай обеспечим ленивое создание, если вдруг ещё null
    final router = _router ??= createAppRouter(ref.read);
    return MaterialApp.router(routerConfig: router, title: 'ListYB');
  }
}
