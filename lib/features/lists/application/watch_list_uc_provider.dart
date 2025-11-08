import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/db/app_database.dart';
import '../../../data/db/db_provider.dart';

/// Параметризованный провайдер: наблюдаем одиночный список по id.
final watchListUcProvider = StreamProvider.family<ListsTableData?, int>((
  ref,
  listId,
) {
  final db = ref.watch(appDatabaseProvider);
  return db.listsDao.watchOne(listId);
});

/// Параметризованный провайдер: наблюдаем элементы конкретного списка,
/// c опциональными фильтрами (completed/query).
class ItemsFilter {
  const ItemsFilter({this.completed, this.query});
  final bool? completed;
  final String? query;

  ItemsFilter copyWith({bool? completed, String? query}) => ItemsFilter(
    completed: completed ?? this.completed,
    query: query ?? this.query,
  );
}

final watchItemsByListProvider =
    StreamProvider.family<
      List<ItemsTableData>,
      ({int listId, ItemsFilter filter})
    >((ref, args) {
      final db = ref.watch(appDatabaseProvider);
      return db.itemsDao.watchByList(
        args.listId,
        completed: args.filter.completed,
        query: args.filter.query,
      );
    });
