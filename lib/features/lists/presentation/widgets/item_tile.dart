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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final tile = ListTile(
      leading: Checkbox(
        key: Key('item_checkbox_${item.id}'),
        value: item.isDone,
        onChanged: (_) => onToggle(),
      ),
      title: Text(
        item.title,
        softWrap: true,
        maxLines: null,
        overflow: TextOverflow.visible,
      ),
      // Контекстное меню больше не нужно — работаем свайпами на уровне списка
      onLongPress: null,
      trailing: null,
    );

    // Оборачиваем в Focus, чтобы элемент мог получать фокус (без клавиатуры)
    return Focus(
      focusNode: focusNode,
      child: Card(
        // margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        surfaceTintColor: isDark ? cs.primary.withValues(alpha: 0.10) : null,
        color: isDark
            ? cs.surfaceContainerHighest.withValues(alpha: 0.18)
            : null,
        child: tile,
      ),
    );
  }
}
