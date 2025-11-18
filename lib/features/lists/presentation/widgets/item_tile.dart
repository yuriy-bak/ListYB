import 'package:flutter/material.dart';
import 'package:listyb/domain/entities/yb_item.dart';

class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.item,
    required this.itemIndex,
    required this.dndEnabled,
    required this.onToggle,
    required this.onDelete,
    this.onEdit,
    this.focusNode,
  });

  final YbItem item;
  final int itemIndex;
  final bool dndEnabled;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onEdit;

  /// Узел фокуса — чтобы можно было сфокусировать элемент программно (после Undo)
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final tile = ListTile(
      leading: Checkbox(
        key: Key('item_checkbox_${item.id}'),
        value: item.isDone,
        onChanged: (_) => onToggle(),
      ),
      title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      // Контекстное меню больше не нужно — работаем свайпами на уровне списка
      onLongPress: null,
      trailing: dndEnabled
          ? ReorderableDragStartListener(
              key: Key('drag_${item.id}'),
              index: itemIndex, // значение индекса игнорируется с builder’ом
              child: const Icon(Icons.drag_handle),
            )
          : null,
    );

    // Оборачиваем в Focus, чтобы элемент мог получать фокус (без клавиатуры)
    return Focus(
      focusNode: focusNode,
      child: Material(child: tile),
    );
  }
}
