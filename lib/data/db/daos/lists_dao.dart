import 'package:drift/drift.dart';
import '../app_database.dart';

part 'lists_dao.g.dart';

@DriftAccessor(tables: [ListsTable, ItemsTable])
class ListsDao extends DatabaseAccessor<AppDatabase> with _$ListsDaoMixin {
  ListsDao(super.db);

  Future<int> insertList(ListsTableCompanion data) =>
      into(listsTable).insert(data);

  /// Convenience для тестов: создать список с текущими метками времени
  Future<int> createList(String title) {
    final now = DateTime.now();
    return insertList(
      ListsTableCompanion.insert(
        title: title.trim(),
        archived: const Value(false),
        sortOrder: const Value(0),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> updateList(int id, ListsTableCompanion data) =>
      (update(listsTable)..where((t) => t.id.equals(id))).write(data);

  /// Вернуть одну запись по id
  Future<ListsTableData> getById(int id) =>
      (select(listsTable)..where((t) => t.id.equals(id))).getSingle();

  /// Обновить заголовок; вернуть число изменённых строк
  Future<int> updateTitle(int id, String title) {
    final now = DateTime.now();
    return (update(listsTable)..where((t) => t.id.equals(id))).write(
      ListsTableCompanion(title: Value(title.trim()), updatedAt: Value(now)),
    );
  }

  /// Поменять флаг архивности; вернуть число изменённых строк
  Future<int> setArchived(int id, {required bool archived}) {
    final now = DateTime.now();
    return (update(listsTable)..where((t) => t.id.equals(id))).write(
      ListsTableCompanion(archived: Value(archived), updatedAt: Value(now)),
    );
  }

  /// Удалить список (+каскадно items); вернуть число удалённых строк
  Future<int> deleteList(int id) =>
      (delete(listsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<ListsTableData>> watchAll({bool includeArchived = false}) {
    final q = select(listsTable)
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.id),
      ]);
    if (!includeArchived) q.where((t) => t.archived.equals(false));
    return q.watch();
  }

  Stream<ListsTableData?> watchOne(int id) =>
      (select(listsTable)..where((t) => t.id.equals(id))).watchSingleOrNull();

  Stream<Map<int, ({int total, int active, int done})>> watchCountsForAll({
    bool includeArchived = false,
  }) {
    final sql =
        '''
      SELECT l.id AS listId,
             COUNT(i.id) AS total,
             SUM(CASE WHEN i.is_done = 0 THEN 1 ELSE 0 END) AS active,
             SUM(CASE WHEN i.is_done = 1 THEN 1 ELSE 0 END) AS done
      FROM lists_table l
      LEFT JOIN items_table i ON i.list_id = l.id
      ${includeArchived ? '' : 'WHERE l.archived = 0'}
      GROUP BY l.id
    ''';
    return customSelect(sql, readsFrom: {listsTable, itemsTable}).watch().map((
      rows,
    ) {
      final map = <int, ({int total, int active, int done})>{};
      for (final r in rows) {
        map[r.read<int>('listId')] = (
          total: r.read<int>('total'),
          active: r.read<int?>('active') ?? 0,
          done: r.read<int?>('done') ?? 0,
        );
      }
      return map;
    });
  }

  Stream<({int total, int active, int done})> watchCounts(int listId) {
    final sql = '''
      SELECT COUNT(i.id) AS total,
             SUM(CASE WHEN i.is_done = 0 THEN 1 ELSE 0 END) AS active,
             SUM(CASE WHEN i.is_done = 1 THEN 1 ELSE 0 END) AS done
      FROM items_table i
      WHERE i.list_id = ?
    ''';
    return customSelect(
      sql,
      variables: [Variable.withInt(listId)],
      readsFrom: {itemsTable},
    ).watchSingle().map(
      (r) => (
        total: r.read<int>('total'),
        active: r.read<int?>('active') ?? 0,
        done: r.read<int?>('done') ?? 0,
      ),
    );
  }
}
