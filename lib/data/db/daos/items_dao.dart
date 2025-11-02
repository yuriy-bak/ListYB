import 'package:drift/drift.dart';

import '../app_database.dart';

part 'items_dao.g.dart';

@DriftAccessor(tables: [Items])
class ItemsDao extends DatabaseAccessor<AppDatabase> with _$ItemsDaoMixin {
  ItemsDao(super.db);

  Future<int> createItem({
    required int listId,
    required String title,
    String? note,
    DateTime? dueAt,
  }) async {
    final now = DateTime.now();
    final maxPosExpr = items.position.max();
    final maxRow =
        await (selectOnly(items)
              ..addColumns([maxPosExpr])
              ..where(items.listId.equals(listId)))
            .getSingleOrNull();

    final currentMax = maxRow?.read(maxPosExpr) ?? 0;
    final count = await countByList(listId);
    final nextPos = count == 0 ? 0 : currentMax + 1;

    return into(items).insert(
      ItemsCompanion.insert(
        listId: listId,
        title: title,
        note: Value(note),
        completed: const Value(false),
        createdAt: now,
        dueAt: Value(dueAt),
        position: Value(nextPos), // <= важно: Value<int>
      ),
    );
  }

  Future<ItemEntity?> getById(int id) {
    return (select(items)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Возвращаем int (кол-во изменённых строк), т.к. используем write()
  Future<int> updateItem({
    required int id,
    String? title,
    String? note,
    DateTime? dueAt,
    bool? completed,
  }) {
    final comp = ItemsCompanion(
      title: title != null ? Value(title) : const Value.absent(),
      note: note != null ? Value(note) : const Value.absent(),
      dueAt: dueAt != null ? Value(dueAt) : const Value.absent(),
      completed: completed != null ? Value(completed) : const Value.absent(),
    );
    return (update(items)..where((t) => t.id.equals(id))).write(comp);
  }

  Future<int> deleteItem(int id) {
    return (delete(items)..where((t) => t.id.equals(id))).go();
  }

  Future<int> countByList(int listId) async {
    final c = items.id.count();
    final row =
        await (selectOnly(items)
              ..addColumns([c])
              ..where(items.listId.equals(listId)))
            .getSingle();
    return row.read(c) ?? 0;
  }

  Stream<List<ItemEntity>> watchByList(
    int listId, {
    String? query,
    bool? completed,
  }) {
    final sel = select(items)
      ..where((t) => t.listId.equals(listId))
      ..orderBy([(t) => OrderingTerm.asc(t.position)]);

    if (query != null && query.isNotEmpty) {
      sel.where((t) => t.title.like('%$query%'));
    }
    if (completed != null) {
      sel.where((t) => t.completed.equals(completed));
    }
    return sel.watch();
  }

  Future<void> reorder({
    required int listId,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex == newIndex) return;

    await transaction(() async {
      final moved =
          await (select(items)..where(
                (t) => t.listId.equals(listId) & t.position.equals(oldIndex),
              ))
              .getSingleOrNull();

      if (moved == null) {
        throw ArgumentError(
          'Нет элемента с position=$oldIndex в listId=$listId',
        );
      }

      final maxPosExpr = items.position.max();
      final maxRow =
          await (selectOnly(items)
                ..addColumns([maxPosExpr])
                ..where(items.listId.equals(listId)))
              .getSingleOrNull();
      final maxPos = maxRow?.read(maxPosExpr) ?? 0;

      if (newIndex < 0 || newIndex > maxPos) {
        throw ArgumentError(
          'newIndex=$newIndex вне диапазона [0..$maxPos] для listId=$listId',
        );
      }

      // Временно убираем переносимый элемент
      await (update(items)
            ..where((t) => t.id.equals(moved.id) & t.listId.equals(listId)))
          .write(const ItemsCompanion(position: Value(-1)));

      if (newIndex > oldIndex) {
        await customUpdate(
          'UPDATE items '
          'SET position = position - 1 '
          'WHERE list_id = ? AND position > ? AND position <= ?',
          variables: [
            Variable.withInt(listId),
            Variable.withInt(oldIndex),
            Variable.withInt(newIndex),
          ],
          updates: {items},
        );
      } else {
        await customUpdate(
          'UPDATE items '
          'SET position = position + 1 '
          'WHERE list_id = ? AND position >= ? AND position < ?',
          variables: [
            Variable.withInt(listId),
            Variable.withInt(newIndex),
            Variable.withInt(oldIndex),
          ],
          updates: {items},
        );
      }

      await (update(items)
            ..where((t) => t.id.equals(moved.id) & t.listId.equals(listId)))
          .write(ItemsCompanion(position: Value(newIndex)));
    });
  }
}
