// lib/features/lists/presentation/widgets/list_actions_menu.dart
import 'package:flutter/material.dart';
import 'package:listyb/l10n/l10n_stub.dart';
import 'package:listyb/domain/entities/yb_list.dart';

enum ListAction { rename, archive, unarchive, delete }

/// Показать контекстное меню списков (PopupMenu) в заданной позиции.
/// Возвращает выбранное действие или null.
Future<ListAction?> showListContextMenu({
  required BuildContext context,
  required Offset globalPosition,
  required YbList list,
}) {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  final overlaySize = overlay?.size ?? MediaQuery.of(context).size;

  final position = RelativeRect.fromLTRB(
    globalPosition.dx,
    globalPosition.dy,
    overlaySize.width - globalPosition.dx,
    overlaySize.height - globalPosition.dy,
  );

  final items = <PopupMenuEntry<ListAction>>[
    PopupMenuItem<ListAction>(
      value: ListAction.rename,
      child: Text(L10n.t(context, 'list.rename')),
    ),
    if (!list.archived)
      PopupMenuItem<ListAction>(
        value: ListAction.archive,
        child: Text(L10n.t(context, 'list.archive')),
      )
    else
      PopupMenuItem<ListAction>(
        value: ListAction.unarchive,
        child: Text(L10n.t(context, 'list.unarchive')),
      ),
    const PopupMenuDivider(),
    PopupMenuItem<ListAction>(
      value: ListAction.delete,
      child: Text(L10n.t(context, 'list.delete')),
    ),
  ];

  return showMenu<ListAction>(
    context: context,
    items: items,
    position: position,
  );
}
