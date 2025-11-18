import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listyb/domain/entities/yb_item.dart';
import 'package:listyb/domain/entities/yb_list.dart';
import 'package:listyb/features/lists/application/items_filter.dart';
import 'package:listyb/di/usecase_providers.dart';

/// Фильтр по состоянию (пер-лист).
final itemsFilterProvider = StateProvider.family<ItemsFilter, int>(
  (ref, listId) => const ItemsFilter.all(),
);

/// Поисковая строка (пер-лист).
final itemsQueryProvider = StateProvider.family<String, int>(
  (ref, listId) => '',
);

/// Поток «всех» элементов без фильтра/поиска — для DnD/Undo.
final allItemsStreamProvider = StreamProvider.family
    .autoDispose<List<YbItem>, int>((ref, listId) {
      final uc = ref.watch(watchItemsUcProvider);
      return uc(listId);
    });

/// Поток элементов с учётом фильтра и строки поиска.
final itemsFilteredStreamProvider = StreamProvider.family
    .autoDispose<List<YbItem>, int>((ref, listId) {
      final filter = ref.watch(itemsFilterProvider(listId));
      final query = ref.watch(itemsQueryProvider(listId)).trim();
      final uc = ref.watch(watchItemsFilteredUcProvider);

      bool? onlyDone;
      bool? onlyActive;
      if (filter.completed == true) {
        onlyDone = true;
      } else if (filter.completed == false) {
        onlyActive = true;
      }

      return uc(
        listId,
        onlyDone: onlyDone,
        onlyActive: onlyActive,
        query: query.isEmpty ? null : query,
      );
    });

/// Поток самой сущности списка (для AppBar и т. п.)
final watchListStreamProvider = StreamProvider.family.autoDispose<YbList?, int>(
  (ref, listId) {
    final uc = ref.watch(watchListUcProvider);
    return uc(listId);
  },
);

/// DnD включён только если фильтр «все» и нет поиска — ВАРИАНТ ДЛЯ ЭКРАНА (пер-лист).
final dndEnabledForListProvider = Provider.autoDispose.family<bool, int>((
  ref,
  listId,
) {
  final f = ref.watch(itemsFilterProvider(listId));
  final q = ref.watch(itemsQueryProvider(listId));
  return f.completed == null && q.trim().isEmpty;
});

// --- ЛЕГАСИ-ПРОВАЙДЕРЫ ДЛЯ СОВМЕСТИМОСТИ С ТЕСТАМИ ---
final _legacyItemsFilterProvider = StateProvider.autoDispose<ItemsFilter>(
  (ref) => const ItemsFilter.all(),
);
final _legacyItemsQueryProvider = StateProvider.autoDispose<String>(
  (ref) => '',
);

/// Несемейный вариант, который ожидают текущие тесты.
final dndEnabledProvider = Provider.autoDispose<bool>((ref) {
  final f = ref.watch(_legacyItemsFilterProvider);
  final q = ref.watch(_legacyItemsQueryProvider);
  return f.completed == null && q.trim().isEmpty;
});
