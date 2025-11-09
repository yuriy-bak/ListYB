// lib/features/lists/presentation/widgets/list_card.dart
import 'package:flutter/material.dart';
import 'package:listyb/domain/entities/yb_counts.dart';
import 'package:listyb/domain/entities/yb_list.dart';

/// Карточка списка с бейджем open/total и поддержкой long-press (контекстное меню).
/// Заголовок переносится на несколько строк и карточка увеличивается по высоте
/// автоматически, чтобы пользователь видел весь текст.
class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.list,
    required this.counts,
    required this.onTap,
    required this.onLongPressAt, // передаём глобальные координаты для showMenu
  });

  final YbList list;
  final YbCounts? counts;
  final VoidCallback onTap;
  final void Function(Offset globalPosition) onLongPressAt;

  @override
  Widget build(BuildContext context) {
    final open = counts?.active ?? 0;
    final total = counts?.total ?? 0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPressStart: (details) {
        onLongPressAt(details.globalPosition);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Многострочный заголовок с переносами
              Expanded(
                child: Text(
                  list.title,
                  softWrap: true,
                  maxLines: null,
                  overflow: TextOverflow.visible,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 12),
              // Бейдж open/total справа, не влияет на перенос заголовка
              _Badge(open: open, total: total),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.open, required this.total});
  final int open;
  final int total;

  @override
  Widget build(BuildContext context) {
    final text = '$open/$total';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
