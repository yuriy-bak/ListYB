import 'package:flutter_test/flutter_test.dart';
import 'package:listyb/core/clock/clock.dart';
import 'package:listyb/data/db/app_database.dart';
import 'package:listyb/data/db/daos/items_dao.dart';
import 'package:listyb/data/db/daos/lists_dao.dart';
import 'package:listyb/data/repositories/items_repository_impl.dart';
import 'package:listyb/data/repositories/lists_repository_impl.dart';
import 'package:listyb/domain/usecases/items/add_item_uc.dart';
import 'package:listyb/domain/usecases/items/reorder_items_uc.dart';
import 'package:listyb/domain/usecases/lists/create_list_uc.dart';

class FixedClock implements Clock {
  final DateTime _now;
  FixedClock(this._now);
  @override
  DateTime now() => _now;
}

void main() {
  test('add, toggle, reorder items and counts reflect', () async {
    final db = makeInMemoryDb();
    final clock = FixedClock(DateTime.utc(2025, 1, 1));

    final listsRepo = ListsRepositoryImpl(ListsDao(db), clock);
    final itemsRepo = ItemsRepositoryImpl(ItemsDao(db), db, clock);

    final createList = CreateListUc(listsRepo);
    final addItem = AddItemUc(itemsRepo);
    final reorder = ReorderItemsUc(itemsRepo);

    final listId = await createList('Groceries');

    final milk = await addItem(listId, 'Milk'); // pos 0
    final bread = await addItem(listId, 'Bread'); // pos 1
    final rice = await addItem(listId, 'Rice'); // pos 2

    await itemsRepo.toggle(milk);
    final milkRow = await itemsRepo.watchOne(milk).first;
    expect(milkRow?.isDone, true);
    expect(milkRow?.completedAt, isNotNull);

    // reorder: Rice, Milk, Bread
    await reorder(listId, [rice, milk, bread]);
    final items = await itemsRepo.watchForList(listId).first;
    expect(items.map((e) => e.title).toList(), ['Rice', 'Milk', 'Bread']);

    final counts = await listsRepo.watchCounts(listId).first;
    expect(counts.done, 1);
    expect(counts.active, 2);
    expect(counts.total, 3);
  });
}
