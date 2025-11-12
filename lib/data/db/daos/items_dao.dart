import 'package:drift/drift.dart';
import '../app_database.dart';

part 'items_dao.g.dart';

@DriftAccessor(tables: [ItemsTable])
class ItemsDao extends DatabaseAccessor<AppDatabase> with _$ItemsDaoMixin {
  ItemsDao(super.db);

  Future<int> insertItem(ItemsTableCompanion data) =>
      into(itemsTable).insert(data);

  /// Convenience для тестов
  Future<int> createItem({
    required int listId,
    required String title,
    int position = 0,
    String? note,
  }) {
    final now = DateTime.now();
    return insertItem(
      ItemsTableCompanion.insert(
        listId: listId,
        title: title.trim(),
        isDone: const Value(false),
        position: Value(position),
        createdAt: now,
        updatedAt: now,
        completedAt: const Value(null),
        note: Value(note),
      ),
    );
  }

  Future<ItemsTableData> getById(int id) =>
      (select(itemsTable)..where((t) => t.id.equals(id))).getSingle();

  Future<void> updateItemRaw(int id, ItemsTableCompanion data) =>
      (update(itemsTable)..where((t) => t.id.equals(id))).write(data);

  /// Обновление по именованным параметрам (под тесты)
  Future<void> updateItem({
    required int id,
    bool? completed,
    String? title,
    String? note,
    int? position,
  }) async {
    final now = DateTime.now();
    final companion = ItemsTableCompanion(
      // изменяем только переданные поля
      isDone: completed == null ? const Value.absent() : Value(completed),
      title: title == null ? const Value.absent() : Value(title.trim()),
      note: note == null ? const Value.absent() : Value(note),
      position: position == null ? const Value.absent() : Value(position),
      updatedAt: Value(now),
      // completedAt ставим только если меняется completed
      completedAt: completed == null
          ? const Value.absent()
          : Value(completed ? now : null),
    );
    await (update(itemsTable)..where((t) => t.id.equals(id))).write(companion);
  }

  Future<void> deleteItem(int id) =>
      (delete(itemsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<ItemsTableData>> watchByList(
    int listId, {
    bool? completed, // true -> только выполненные, false -> только активные
    String? query, // поиск по title/note, LIKE %query%
  }) {
    final q = (select(itemsTable)
      ..where((t) => t.listId.equals(listId))
      ..orderBy([
        (t) => OrderingTerm.asc(t.position),
        (t) => OrderingTerm.asc(t.id),
      ]));

    if (completed != null) {
      q.where((t) => t.isDone.equals(completed));
    }

    if (query != null && query.trim().isNotEmpty) {
      final like = '%${query.trim()}%';
      // Поиск по title ИЛИ note
      q.where((t) => t.title.like(like) | t.note.like(like));
    }

    return q.watch();
  }

  Stream<ItemsTableData?> watchOne(int id) =>
      (select(itemsTable)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<void> reorderItems(int listId, List<int> orderedIds) async {
    await transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (update(itemsTable)..where(
              (t) => t.id.equals(orderedIds[i]) & t.listId.equals(listId),
            ))
            .write(ItemsTableCompanion(position: Value(i)));
      }
    });
  }

  /// Перемещает элемент с позиции oldIndex в позицию newIndex внутри списка
  Future<void> reorder({
    required int listId,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex == newIndex) return;

    await transaction(() async {
      // Текущий порядок
      final rows =
          await (select(itemsTable)
                ..where((t) => t.listId.equals(listId))
                ..orderBy([
                  (t) => OrderingTerm.asc(t.position),
                  (t) => OrderingTerm.asc(t.id),
                ]))
              .get();

      if (rows.isEmpty) return;
      if (oldIndex < 0 || oldIndex >= rows.length) return;
      if (newIndex < 0 || newIndex >= rows.length) return;

      final list = List<ItemsTableData>.from(rows);
      final moved = list.removeAt(oldIndex);
      list.insert(newIndex, moved);

      // Переприсваиваем position
      for (var i = 0; i < list.length; i++) {
        final it = list[i];
        await (update(itemsTable)..where((t) => t.id.equals(it.id))).write(
          ItemsTableCompanion(position: Value(i)),
        );
      }
    });
  }
}
