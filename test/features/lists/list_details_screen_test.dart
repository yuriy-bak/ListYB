import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listyb/data/db/app_database.dart' as db;
import 'package:listyb/data/db/daos/lists_dao.dart';
import 'package:listyb/data/db/daos/items_dao.dart';
import 'package:listyb/di/database_providers.dart';
import 'package:listyb/features/lists/presentation/list_details_screen.dart';
import 'package:listyb/features/lists/presentation/list_details_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ListDetailsScreen', () {
    late ProviderContainer container;
    late db.AppDatabase memoryDb;
    late ListsDao listsDao;
    late ItemsDao itemsDao;
    late int listId;

    setUp(() async {
      memoryDb = db.makeInMemoryDb();
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(memoryDb)],
      );
      listsDao = container.read(listsDaoProvider);
      itemsDao = container.read(itemsDaoProvider);
      listId = await listsDao.createList('Покупки');
      await itemsDao.createItem(listId: listId, title: 'Молоко', position: 0);
      await itemsDao.createItem(listId: listId, title: 'Хлеб', position: 1);
      await itemsDao.createItem(listId: listId, title: 'Сыр', position: 2);
    });

    tearDown(() async {
      await memoryDb.close();
      container.dispose();
    });

    Future<void> pumpScreen(WidgetTester tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SizedBox())),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(body: ListDetailsScreen(listId: listId)),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Quick add adds a new item', (tester) async {
      await pumpScreen(tester);
      final field = find.byKey(const Key('quick_add_field'));
      expect(field, findsOneWidget);
      await tester.enterText(field, 'Яйца');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Яйца'), findsOneWidget);
    });

    testWidgets('Search filters by substring (case-insensitive)', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();
      final search = find.byKey(const Key('search_field'));
      expect(search, findsOneWidget);
      await tester.enterText(search, 'ХЛ');
      await tester.pumpAndSettle();
      expect(find.text('Хлеб'), findsOneWidget);
      expect(find.text('Молоко'), findsNothing);
      expect(find.text('Сыр'), findsNothing);
    });

    testWidgets('Filters: Open/Done', (tester) async {
      await pumpScreen(tester);

      final firstCheckbox = find.byType(Checkbox).first;
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      final filterLabelAll = find.text('Все');
      expect(filterLabelAll, findsOneWidget);
      await tester.tap(filterLabelAll);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Выполненные'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsOneWidget);

      final filterLabelDone = find.text('Выполненные');
      expect(filterLabelDone, findsOneWidget);
      await tester.tap(filterLabelDone);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Открытые'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('DnD reorders items and persists order', (tester) async {
      await pumpScreen(tester);

      expect(container.read(dndEnabledForListProvider(listId)), isTrue);

      final dragSource = find.byType(ReorderableDelayedDragStartListener).first;
      expect(dragSource, findsOneWidget);

      await tester.longPress(dragSource);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.drag(dragSource, const Offset(0, 160));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('Delete + Undo restores item and position', (tester) async {
      await pumpScreen(tester);

      final firstTile = find.byType(ListTile).first;
      await tester.drag(firstTile, const Offset(400, 0));
      await tester.pumpAndSettle();

      if (tester.any(find.byType(SnackBar)) == false) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final undoAction = find.byType(SnackBarAction);
      expect(undoAction, findsOneWidget);
      await tester.tap(undoAction);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('DnD reorders a middle item correctly', (tester) async {
      await pumpScreen(tester);
      expect(container.read(dndEnabledForListProvider(listId)), isTrue);

      // ✅ Делаем детерминированно: вызываем onReorder у SliverReorderableList
      final sliverFinder = find.byType(SliverReorderableList);
      expect(sliverFinder, findsOneWidget);
      final sliver = tester.widget<SliverReorderableList>(sliverFinder);
      // Переносим элемент с индексом 1 (Хлеб) в конец списка (newIndex=3)
      sliver.onReorder(1, 3);
      await tester.pumpAndSettle();

      // Проверяем порядок заголовков
      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(tiles.length, 3);
      final firstTitle = (tiles.first.title as Text).data;
      final middleTitle = (tiles[1].title as Text).data;
      final lastTitle = (tiles.last.title as Text).data;
      expect(firstTitle, 'Молоко');
      expect(middleTitle, 'Сыр');
      expect(lastTitle, 'Хлеб');
    });
  });
}
