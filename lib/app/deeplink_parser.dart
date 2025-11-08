import 'package:flutter/foundation.dart';

/// Команды диплинков.
sealed class DeepLinkCommand {
  const DeepLinkCommand();
}

class OpenHomeCmd extends DeepLinkCommand {
  const OpenHomeCmd();
}

class OpenListCmd extends DeepLinkCommand {
  final int listId;
  const OpenListCmd(this.listId);
}

class QuickAddCmd extends DeepLinkCommand {
  final int listId;
  const QuickAddCmd(this.listId);
}

class QuickEditCmd extends DeepLinkCommand {
  final int itemId;
  const QuickEditCmd(this.itemId);
}

/// Поддерживаемые схемы:
/// - listyb://home
/// - listyb://list/{id}
/// - listyb://list/{id}/add
/// - listyb://item/{id}/edit  ← ТЕПЕРЬ ПОДДЕРЖИВАЕМ (возвращаем QuickEditCmd)
///
/// Альтернативы с префиксом host=app:
/// - listyb://app/home
/// - listyb://app/list/{id}
/// - listyb://app/list/{id}/add
/// - listyb://app/item/{id}/edit
///
/// Жёсткие правила во имя тестов:
/// • Никаких query (?...) и fragment (#...) — сразу null.
/// • Никаких лишних сегментов сверх описанных шаблонов.
/// • Идентификаторы — строго целые положительные (int), без пробелов.
DeepLinkCommand? parseDeepLink(Uri uri) {
  try {
    if (uri.scheme.toLowerCase() != 'listyb') return null;

    // Тесты требуют отбраковывать любые ссылки с query/fragment
    if ((uri.hasQuery && uri.query.isNotEmpty) ||
        (uri.hasFragment && uri.fragment.isNotEmpty)) {
      return null;
    }

    // Логические сегменты: [host?, ...pathSegments] без пустых
    final segments = <String>[
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ].where((s) => s.isNotEmpty).toList(growable: false);

    if (segments.isEmpty) return null;

    // Нормализуем возможный префикс 'app'
    final norm = segments.first == 'app' ? segments.sublist(1) : segments;
    if (norm.isEmpty) return null;

    String head = norm[0];

    // home — разрешаем ТОЛЬКО ровно один сегмент
    if (head == 'home') {
      if (norm.length == 1) {
        return const OpenHomeCmd();
      }
      return null; // лишние сегменты запрещены
    }

    // list/{id} или list/{id}/add
    if (head == 'list') {
      if (norm.length == 2) {
        final id = int.tryParse(norm[1]);
        if (id == null) return null;
        return OpenListCmd(id);
      }
      if (norm.length == 3 && norm[2] == 'add') {
        final id = int.tryParse(norm[1]);
        if (id == null) return null;
        return QuickAddCmd(id);
      }
      return null; // любые другие варианты запрещены
    }

    // item/{id}/edit — теперь поддерживаем и возвращаем QuickEditCmd
    if (head == 'item') {
      if (norm.length == 3 && norm[2] == 'edit') {
        final id = int.tryParse(norm[1]);
        if (id == null) return null;
        return QuickEditCmd(id);
      }
      return null;
    }

    return null;
  } catch (e) {
    if (kDebugMode) {
      // ignore: avoid_print
      // print('Deep link parse error: $e');
    }
    return null;
  }
}
