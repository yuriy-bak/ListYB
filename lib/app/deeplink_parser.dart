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
/// - listyb://item/{id}/edit
///
/// И альтернативы с префиксом host=app:
/// - listyb://app/home
/// - listyb://app/list/{id}
/// - listyb://app/list/{id}/add
/// - listyb://app/item/{id}/edit
///
/// Важно: у кастомных схем первый «сегмент» пути часто оказывается в host.
///
/// Примеры:
/// listyb://list/42    -> host: "list", pathSegments: ["42"]
/// listyb://item/9/edit-> host: "item", pathSegments: ["9","edit"]
/// listyb://app/list/7 -> host: "app",  pathSegments: ["list","7"]
DeepLinkCommand? parseDeepLink(Uri uri) {
  try {
    if (uri.scheme.toLowerCase() != 'listyb') return null;

    // Собираем логические сегменты с учётом host:
    // [host?, ...pathSegments] и убираем пустые.
    final segments = <String>[
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ].where((s) => s.isNotEmpty).toList(growable: false);

    if (segments.isEmpty) return null;

    // Нормализуем возможный префикс 'app'
    // listyb://app/list/123 -> ["app","list","123"] => отбрасываем "app"
    final norm = segments.first == 'app' ? segments.sublist(1) : segments;
    if (norm.isEmpty) return null;

    final head = norm[0];

    // home
    if (head == 'home') {
      // Допускаем как ровно ["home"], так и c лишними хвостами, но игнорируем их
      return const OpenHomeCmd();
    }

    // list/{id} [/add]
    if (head == 'list') {
      if (norm.length >= 2) {
        final id = int.tryParse(norm[1]);
        if (id == null) return null;
        if (norm.length >= 3 && norm[2] == 'add') {
          return QuickAddCmd(id);
        }
        return OpenListCmd(id);
      }
      return null;
    }

    // item/{id}/edit
    if (head == 'item') {
      if (norm.length >= 3 && norm[2] == 'edit') {
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
