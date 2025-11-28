// test/features/lists/lists_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listyb/features/lists/presentation/lists_screen.dart';
import 'package:listyb/di/stream_providers.dart';
import 'package:listyb/features/common/undo/undo_snackbar_service.dart';
import 'package:listyb/domain/entities/yb_list.dart';
import 'package:listyb/domain/entities/yb_counts.dart';
import 'package:listyb/features/lists/presentation/widgets/list_actions_menu.dart';
import 'package:listyb/di/database_providers.dart';
import 'package:listyb/data/db/app_database.dart' as db;
import 'package:drift/drift.dart' as drift;

void main() {
  testWidgets('Пустое состояние отображается', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listsStreamProvider.overrideWith((ref) => Stream.value(<YbList>[])),
          countsForAllStreamProvider.overrideWith(
            (ref) => Stream.value(<int, YbCounts>{}),
          ),
        ],
        child: const MaterialApp(home: ListsScreen()),
      ),
    );

    await tester.pump();
    expect(find.text('Нет списков — создайте первый'), findsOneWidget);
  });

  testWidgets('Список карточек и бейджи open', (tester) async {
    final lists = <YbList>[
      YbList(
        id: 1,
        title: 'Список А',
        archived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 0,
      ),
      YbList(
        id: 2,
        title: 'Список B',
        archived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 1,
      ),
    ];
    final counts = <int, YbCounts>{
      1: const YbCounts(total: 5, active: 3, done: 2),
      2: const YbCounts(total: 0, active: 0, done: 0),
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listsStreamProvider.overrideWith((ref) => Stream.value(lists)),
          countsForAllStreamProvider.overrideWith(
            (ref) => Stream.value(counts),
          ),
        ],
        child: const MaterialApp(home: ListsScreen()),
      ),
    );

    await tester.pump();
    expect(find.text('Список А'), findsOneWidget);
    expect(find.text('Список B'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
  });

  testWidgets('Контекстное меню: Архивировать вызывает сервис Undo', (
    tester,
  ) async {
    final lists = <YbList>[
      YbList(
        id: 1,
        title: 'Work',
        archived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 0,
      ),
    ];
    final counts = <int, YbCounts>{
      1: const YbCounts(total: 2, active: 1, done: 1),
    };

    final calls = <String>[];
    final fakeUndoProvider = undoServiceProvider.overrideWithValue(
      _FakeUndoService(
        onArchive: (listId, archived) => calls.add('archive:$listId:$archived'),
        onDelete: (listId) => calls.add('delete:$listId'),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listsStreamProvider.overrideWith((ref) => Stream.value(lists)),
          countsForAllStreamProvider.overrideWith(
            (ref) => Stream.value(counts),
          ),
          fakeUndoProvider,
        ],
        child: const MaterialApp(home: ListsScreen()),
      ),
    );

    await tester.pump();

    final tile = find.text('Work');
    expect(tile, findsOneWidget);

    final box = tester.firstRenderObject<RenderBox>(tile);
    final pos = box.localToGlobal(Offset.zero) + const Offset(10, 10);

    await tester.longPressAt(pos);
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(PopupMenuItem<ListAction>, 'Архивировать'),
    );
    await tester.pumpAndSettle();

    expect(calls, contains('archive:1:true'));
  });

  testWidgets('Контекстное меню: Удалить -> диалог -> подтверждение', (
    tester,
  ) async {
    final lists = <YbList>[
      YbList(
        id: 42,
        title: 'To delete',
        archived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 0,
      ),
    ];
    final counts = <int, YbCounts>{
      42: const YbCounts(total: 1, active: 1, done: 0),
    };

    final calls = <String>[];
    final fakeUndoProvider = undoServiceProvider.overrideWithValue(
      _FakeUndoService(
        onArchive: (context, _) {},
        onDelete: (listId) => calls.add('delete:$listId'),
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listsStreamProvider.overrideWith((ref) => Stream.value(lists)),
          countsForAllStreamProvider.overrideWith(
            (ref) => Stream.value(counts),
          ),
          fakeUndoProvider,
        ],
        child: const MaterialApp(home: ListsScreen()),
      ),
    );

    await tester.pump();

    final tile = find.text('To delete');
    final box = tester.firstRenderObject<RenderBox>(tile);
    final pos = box.localToGlobal(Offset.zero) + const Offset(10, 10);

    await tester.longPressAt(pos);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(PopupMenuItem<ListAction>, 'Удалить'));
    await tester.pumpAndSettle();

    final deleteText = find.byWidgetPredicate(
      (w) => w is Text && (w.data?.startsWith('Удалить') ?? false),
    );
    final deleteButton = find.ancestor(
      of: deleteText,
      matching: find.byType(TextButton),
    );

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(calls, contains('delete:42'));
  });

  testWidgets('Перетаскивание меняет порядок и сохраняется в БД', (
    tester,
  ) async {
    final memoryDb = db.makeInMemoryDb();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(memoryDb),
          listsStreamProvider.overrideWith(
            (ref) => ref
                .read(listsDaoProvider)
                .watchAll()
                .map(
                  (rows) => rows
                      .map(
                        (r) => YbList(
                          id: r.id,
                          title: r.title,
                          archived: r.archived,
                          createdAt: r.createdAt,
                          updatedAt: r.updatedAt,
                          sortOrder: r.sortOrder,
                        ),
                      )
                      .toList(),
                ),
          ),
          countsForAllStreamProvider.overrideWith(
            (ref) => Stream.value(<int, YbCounts>{}),
          ),
        ],
        child: const MaterialApp(home: ListsScreen()),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ListsScreen)),
    );
    final listsDao = container.read(listsDaoProvider);

    // Вставляем данные
    final now = DateTime.now();
    await listsDao.insertList(
      db.ListsTableCompanion.insert(
        title: 'A',
        archived: const drift.Value(false),
        sortOrder: const drift.Value(0),
        createdAt: now,
        updatedAt: now,
      ),
    );
    await listsDao.insertList(
      db.ListsTableCompanion.insert(
        title: 'B',
        archived: const drift.Value(false),
        sortOrder: const drift.Value(1),
        createdAt: now,
        updatedAt: now,
      ),
    );

    await tester.pumpAndSettle();

    // ✅ Проверка начального состояния через прямой запрос
    final before = await listsDao.getAllOrdered();

    expect(before.map((e) => e.title).toList(), ['A', 'B']);

    // Вызываем onReorder у SliverReorderableList напрямую
    final sliverFinder = find.byType(SliverReorderableList);
    expect(sliverFinder, findsOneWidget);
    final sliver = tester.widget<SliverReorderableList>(sliverFinder);
    sliver.onReorder(0, 2); // перенос 0-го элемента в конец (станет 1)
    await tester.pumpAndSettle();

    // Проверяем итоговый порядок через прямой запрос
    final after = await listsDao.getAllOrdered();
    expect(after.map((e) => e.title).toList(), ['B', 'A']);

    // ✅ Закрываем контейнер и «выжигаем» таймеры Drift
    container.dispose();
    await tester.pump(const Duration(seconds: 1));
  });
}

class _FakeUndoService implements UndoSnackbarService {
  _FakeUndoService({required this.onArchive, required this.onDelete});
  final void Function(int listId, bool archived) onArchive;
  final void Function(int listId) onDelete;

  @override
  Future<void> archiveWithUndo({
    required BuildContext context,
    required int listId,
    required bool archived,
  }) async {
    onArchive(listId, archived);
  }

  @override
  Future<void> deleteWithUndo({
    required BuildContext context,
    required int listId,
  }) async {
    onDelete(listId);
  }
}
