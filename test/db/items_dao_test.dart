import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show QueryExecutor;

import 'package:listyb/data/db/app_database.dart';
import 'package:listyb/data/db/daos/lists_dao.dart';
import 'package:listyb/data/db/daos/items_dao.dart';

void main() {
  late AppDatabase db;
  late ListsDao listsDao;
  late ItemsDao itemsDao;
  late int listId;

  setUp(() async {
    final QueryExecutor e = NativeDatabase.memory();
    db = AppDatabase.forTesting(e);
    listsDao = ListsDao(db);
    itemsDao = ItemsDao(db);

    listId = await listsDao.createList('Groceries');
  });

  tearDown(() async {
    await db.close();
  });

  test('ItemsDao CRUD + watchByList filters and ordering', () async {
    // Create items A..E with position 0..4
    await itemsDao.createItem(listId: listId, title: 'Apples');
    final b = await itemsDao.createItem(listId: listId, title: 'Bananas');
    await itemsDao.createItem(listId: listId, title: 'Carrots');
    await itemsDao.createItem(listId: listId, title: 'Dates');
    await itemsDao.createItem(listId: listId, title: 'Eggs');

    final firstBatch = await itemsDao.watchByList(listId).first;
    expect(firstBatch.map((x) => x.title).toList(), [
      'Apples',
      'Bananas',
      'Carrots',
      'Dates',
      'Eggs',
    ]);

    await itemsDao.updateItem(id: firstBatch[2].id, completed: true);
    final onlyCompleted = await itemsDao
        .watchByList(listId, completed: true)
        .first;
    expect(onlyCompleted.map((x) => x.title).toList(), ['Carrots']);

    final queryDates = await itemsDao.watchByList(listId, query: 'Da').first;
    expect(queryDates.map((x) => x.title).toList(), ['Dates']);

    await itemsDao.updateItem(id: b, title: 'Bananas (ripe)', note: '2kg');
    final updated = await itemsDao.getById(b);
    expect(updated.title, contains('ripe'));
  });

  test('ItemsDao.reorder transactionally reindexes range', () async {
    await itemsDao.createItem(listId: listId, title: 'A'); // 0
    await itemsDao.createItem(listId: listId, title: 'B'); // 1
    await itemsDao.createItem(listId: listId, title: 'C'); // 2
    await itemsDao.createItem(listId: listId, title: 'D'); // 3
    await itemsDao.createItem(listId: listId, title: 'E'); // 4

    await itemsDao.reorder(listId: listId, oldIndex: 1, newIndex: 3);
    var afterMove = await itemsDao.watchByList(listId).first;
    expect(afterMove.map((x) => x.title).toList(), ['A', 'C', 'D', 'B', 'E']);
    expect(afterMove.map((x) => x.position).toList(), [0, 1, 2, 3, 4]);

    await itemsDao.reorder(listId: listId, oldIndex: 2, newIndex: 0);
    afterMove = await itemsDao.watchByList(listId).first;
    expect(afterMove.map((x) => x.title).toList(), ['D', 'A', 'C', 'B', 'E']);
    expect(afterMove.map((x) => x.position).toList(), [0, 1, 2, 3, 4]);
  });
}
