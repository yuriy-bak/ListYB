import '../entities/yb_item.dart';

abstract class ItemsRepository {
  Future<int> add(int listId, String title, {int? position});
  Future<void> update(YbItem item);
  Future<void> toggle(int itemId);
  Future<void> reorder(int listId, List<int> orderedItemIds);
  Future<void> delete(int itemId);

  Stream<List<YbItem>> watchForList(
    int listId, {
    bool? onlyDone,
    bool? onlyActive,
  });
  Stream<YbItem?> watchOne(int itemId);

  /// Поток с учётом текстового поиска по подстроке (регистронезависимо).
  /// Поиск выполняется на уровне БД (DAO.watchByList(listId, completed, query)).
  Stream<List<YbItem>> watchForListFiltered(
    int listId, {
    bool? onlyDone,
    bool? onlyActive,
    String? query,
  });
}
