import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';

import 'package:listyb/data/db/app_database.dart';
import 'package:listyb/data/db/daos/lists_dao.dart';

void main() {
  late AppDatabase db;
  late ListsDao listsDao;

  setUp(() {
    final QueryExecutor e = NativeDatabase.memory();
    db = AppDatabase.forTesting(e);
    listsDao = ListsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('ListsDao CRUD + watchAll includeArchived=false', () async {
    // initially empty
    final initial = await listsDao.watchAll().first;
    expect(initial, isEmpty);

    final id1 = await listsDao.createList('Groceries');
    final id2 = await listsDao.createList('Hardware');

    // watch non-archived
    final afterCreate = await listsDao.watchAll().first;
    expect(afterCreate.length, 2);

    // archive first
    final archivedOk = await listsDao.setArchived(id1, archived: true);
    expect(archivedOk, 1);

    final afterArchiveDefault = await listsDao.watchAll().first;
    expect(afterArchiveDefault.length, 1);
    expect(afterArchiveDefault.first.id, id2);

    // includeArchived=true — оба
    final withArchived = await listsDao.watchAll(includeArchived: true).first;
    expect(withArchived.length, 2);

    // update title
    final updOk = await listsDao.updateTitle(id2, 'Tools');
    expect(updOk, 1);
    final updated = await listsDao.getById(id2);
    expect(updated?.title, 'Tools');

    // delete list2 -> remains only archived list if we includeArchived
    final deleted = await listsDao.deleteList(id2);
    expect(deleted, 1);
    final finalAll = await listsDao.watchAll(includeArchived: true).first;
    expect(finalAll.length, 1);
    expect(finalAll.first.id, id1);
  });
}
