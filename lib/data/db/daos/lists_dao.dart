import 'package:drift/drift.dart';

import '../app_database.dart';

part 'lists_dao.g.dart';

@DriftAccessor(tables: [Lists])
class ListsDao extends DatabaseAccessor<AppDatabase> with _$ListsDaoMixin {
  ListsDao(super.db);

  Future<int> createList(String title) {
    final now = DateTime.now();
    return into(lists).insert(
      ListsCompanion.insert(
        title: title,
        createdAt: now,
        archivedAt: const Value.absent(),
      ),
    );
  }

  Future<ListEntity?> getById(int id) {
    return (select(lists)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Возвращаем int (кол-во изменённых строк), т.к. используем write()
  Future<int> updateTitle(int id, String title) {
    return (update(lists)..where((t) => t.id.equals(id))).write(
      ListsCompanion(title: Value(title)),
    );
  }

  Future<int> setArchived(int id, {required bool archived}) {
    final Value<DateTime?> v = archived
        ? Value(DateTime.now())
        : const Value(null);
    return (update(
      lists,
    )..where((t) => t.id.equals(id))).write(ListsCompanion(archivedAt: v));
  }

  Future<int> deleteList(int id) {
    return (delete(lists)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<ListEntity>> watchAll({bool includeArchived = false}) {
    final q = select(lists);
    if (!includeArchived) {
      q.where((t) => t.archivedAt.isNull());
    }
    return q.watch();
  }
}
