import 'package:drift/drift.dart';
import '../../core/clock/clock.dart';
import '../../domain/entities/yb_item.dart';
import '../../domain/repositories/items_repository.dart';
import '../db/app_database.dart';
import '../db/daos/items_dao.dart';
import '../mappers/item_mappers.dart';

class ItemsRepositoryImpl implements ItemsRepository {
  final ItemsDao _dao;
  final AppDatabase _db;
  final Clock _clock;
  ItemsRepositoryImpl(this._dao, this._db, this._clock);

  @override
  Future<int> add(int listId, String title, {int? position}) async {
    final now = _clock.now();
    final pos = position ?? await _nextPosition(listId);
    return _dao.insertItem(
      ItemsTableCompanion.insert(
        listId: listId,
        title: title.trim(),
        isDone: const Value(false),
        position: Value(pos),
        createdAt: now,
        updatedAt: now,
        completedAt: const Value(null),
      ),
    );
  }

  Future<int> _nextPosition(int listId) async {
    final q =
        await (_db.select(_db.itemsTable)
              ..where((t) => t.listId.equals(listId))
              ..orderBy([(t) => OrderingTerm.desc(t.position)])
              ..limit(1))
            .get();
    return q.isEmpty ? 0 : q.first.position + 1;
  }

  @override
  Future<void> update(YbItem item) async {
    // Обновляем поля, которые может менять репозиторий
    await _dao.updateItem(
      id: item.id,
      title: item.title,
      note: item.completedAt
          ?.toIso8601String(), // если note из домена не используется — уберите строку
      position: item.position,
      // completed не трогаем здесь (для этого есть toggle)
    );
  }

  @override
  Future<void> toggle(int itemId) async {
    await _db.transaction(() async {
      final row = await (_db.select(
        _db.itemsTable,
      )..where((t) => t.id.equals(itemId))).getSingle();
      final newDone = !row.isDone;
      await _dao.updateItem(id: itemId, completed: newDone);
    });
  }

  @override
  Future<void> reorder(int listId, List<int> orderedItemIds) =>
      _dao.reorderItems(listId, orderedItemIds);

  @override
  Future<void> delete(int itemId) => _dao.deleteItem(itemId);

  @override
  Stream<List<YbItem>> watchForList(
    int listId, {
    bool? onlyDone,
    bool? onlyActive,
  }) {
    bool? completed;
    if (onlyDone == true) completed = true;
    if (onlyActive == true) completed = false;

    return _dao
        .watchByList(listId, completed: completed)
        .map((rows) => rows.map((r) => r.toEntity()).toList());
  }

  @override
  Stream<YbItem?> watchOne(int itemId) =>
      _dao.watchOne(itemId).map((r) => r?.toEntity());
}
