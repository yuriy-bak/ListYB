import 'package:flutter_test/flutter_test.dart';
import 'package:listyb/core/clock/clock.dart';
import 'package:listyb/data/db/app_database.dart';
import 'package:listyb/data/db/daos/lists_dao.dart';
import 'package:listyb/data/repositories/lists_repository_impl.dart';
import 'package:listyb/domain/usecases/lists/archive_list_uc.dart';
import 'package:listyb/domain/usecases/lists/create_list_uc.dart';
import 'package:listyb/domain/usecases/lists/rename_list_uc.dart';

class FixedClock implements Clock {
  final DateTime _now;
  FixedClock(this._now);
  @override
  DateTime now() => _now;
}

void main() {
  test('create/rename/archive list and watch streams', () async {
    final db = makeInMemoryDb();
    final repo = ListsRepositoryImpl(
      ListsDao(db),
      FixedClock(DateTime.utc(2025, 1, 1)),
    );

    final create = CreateListUc(repo);
    final rename = RenameListUc(repo);
    final archive = ArchiveListUc(repo);

    final id = await create('Groceries');
    expect(id, greaterThan(0));

    final lists = await repo.watchAll().first;
    expect(lists.single.title, 'Groceries');

    await rename(id, 'Food');
    final updated = await repo.watchOne(id).first;
    expect(updated?.title, 'Food');

    await archive(id, archived: true);
    final visible = await repo.watchAll().first;
    expect(visible.isEmpty, true);

    final countsMap = await repo.watchCountsForAll().first;
    // в пустом списке элементов counts будет 0; просто проверяем отсутствие списка в выборке
    expect(countsMap.containsKey(id), false);
  });
}
