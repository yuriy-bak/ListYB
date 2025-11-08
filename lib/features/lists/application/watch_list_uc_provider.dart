import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listyb/data/db/app_database.dart';
import 'package:listyb/di/database_providers.dart';
import 'package:listyb/features/lists/application/items_filter.dart';

/// Record-ключ семейства провайдера:
typedef ItemsWatchKey = ({int listId, ItemsFilter filter});

/// Фильтр как управляемое состояние на экран «детали списка»
/// (по желанию — можно хранить локально в виджете/StateNotifier).
final itemsFilterProvider = StateProvider.family<ItemsFilter, int>(
  (ref, listId) => const ItemsFilter(),
);

/// Параметризованный провайдер: наблюдаем одиночный список по id.
final watchListUcProvider = StreamProvider.family<ListsTableData?, int>((
  ref,
  listId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.listsDao.watchOne(listId);
});

/// Главный стрим-провайдер: отдаёт элементы списка с учётом фильтра.
/// Возвращает DTO из БД (ItemsTableData).
final watchItemsByListProvider = StreamProvider.autoDispose
    .family<List<ItemsTableData>, ItemsWatchKey>((ref, key) {
      final db = ref.watch(appDatabaseProvider);

      final String? query = () {
        final q = key.filter.query?.trim();
        if (q == null || q.isEmpty) return null;
        return q;
      }();

      final bool? completed = key.filter.completed;

      // DAO поддерживает параметры (listId, completed, query).
      return db.itemsDao.watchByList(
        key.listId,
        completed: completed,
        query: query,
      );
    });
