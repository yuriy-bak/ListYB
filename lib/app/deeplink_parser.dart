import 'package:flutter/foundation.dart';

/// Команды диплинков.
sealed class DeepLinkCommand {
  const DeepLinkCommand();
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
/// - listyb://list/{id}
/// - listyb://list/{id}/add
/// - listyb://item/{id}/edit
///
/// Важно: у кастомных схем первый «сегмент» пути может оказаться в host.
/// Примеры:
///   listyb://list/42      -> host: "list",  pathSegments: ["42"]
///   listyb://item/9/edit  -> host: "item",  pathSegments: ["9","edit"]
///   listyb:/list/42       -> host: "",      pathSegments: ["list","42"]
DeepLinkCommand? parseDeepLink(Uri uri) {
  try {
    if (uri.scheme != 'listyb') return null;

    // Строго запрещаем "хвосты" в виде query/fragment.
    if ((uri.hasQuery && uri.query.isNotEmpty) || (uri.fragment.isNotEmpty)) {
      return null;
    }

    // Логические сегменты с учётом host.
    final segments = <String>[
      if (uri.host.isNotEmpty) uri.host,
      ...uri.pathSegments,
    ];

    // Нормализуем пустые сегменты.
    final norm = segments.where((s) => s.isNotEmpty).toList(growable: false);
    if (norm.isEmpty) return null;

    final head = norm[0];

    // ----- list/{id} -----
    if (head == 'list') {
      // Ровно 2 сегмента: ["list", "{id}"]
      if (norm.length == 2) {
        final id = int.tryParse(norm[1]);
        return id == null ? null : OpenListCmd(id);
      }
      // Ровно 3 сегмента: ["list", "{id}", "add"]
      if (norm.length == 3 && norm[2] == 'add') {
        final id = int.tryParse(norm[1]);
        return id == null ? null : QuickAddCmd(id);
      }
      return null;
    }

    // ----- item/{id}/edit -----
    if (head == 'item') {
      // Ровно 3 сегмента: ["item", "{id}", "edit"]
      if (norm.length == 3 && norm[2] == 'edit') {
        final id = int.tryParse(norm[1]);
        return id == null ? null : QuickEditCmd(id);
      }
      return null;
    }

    return null;
  } catch (e) {
    if (kDebugMode) {
      // print('Deep link parse error: $e');
    }
    return null;
  }
}
