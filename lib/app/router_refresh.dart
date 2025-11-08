import 'dart:async';
import 'package:flutter/foundation.dart';

/// Адаптер Stream → Listenable для refreshListenable go_router.
/// Совместим со старыми/новыми версиями пакета.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription _sub;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) {
      // достаточно уведомить, значение самому go_router не нужно
      notifyListeners();
    });
  }
  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
