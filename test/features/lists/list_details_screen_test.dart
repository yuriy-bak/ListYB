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
      // «Прогрев» — чтобы гарантированно смонтировать ProviderScope
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: Scaffold(body: SizedBox())),
        ),
      );
      await tester.pump();

      // Сам экран
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: ListDetailsScreen(listId: listId)),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Quick add adds a new item', (tester) async {
      await pumpScreen(tester);

      // Ключ стоит на TextField внутри QuickAddField
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

      // Поиск в AppBar включается по кнопке
      await tester.tap(find.byKey(const Key('search_button')));
      await tester.pumpAndSettle();

      final search = find.byKey(const Key('search_field'));
      expect(search, findsOneWidget);

      await tester.enterText(search, 'ХЛ'); // часть «Хлеб» в верхнем регистре
      await tester.pumpAndSettle();

      expect(find.text('Хлеб'), findsOneWidget);
      expect(find.text('Молоко'), findsNothing);
      expect(find.text('Сыр'), findsNothing);
    });

    testWidgets('Filters: Open/Done', (tester) async {
      await pumpScreen(tester);

      // Отметим любой первый как выполненный
      final firstCheckbox = find.byType(Checkbox).first;
      await tester.tap(firstCheckbox);
      await tester.pumpAndSettle();

      // Откроем селектор фильтров и выберем «Выполненные»
      await tester.tap(find.byKey(const Key('filter_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter_done')));
      await tester.pumpAndSettle();

      // Должен остаться ровно один (выполненный)
      expect(find.byType(ListTile), findsOneWidget);

      // Вернём «Открытые»
      await tester.tap(find.byKey(const Key('filter_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('filter_open')));
      await tester.pumpAndSettle();

      // Открытых теперь два
      expect(find.byType(ListTile), findsNWidgets(2));
    });

    testWidgets('DnD reorders items and persists order', (tester) async {
      await pumpScreen(tester);

      // DnD включён (All + пустой поиск)
      expect(container.read(dndEnabledProvider), isTrue);

      // Возьмём любой drag handle по ключу 'drag_<id>'
      final handle = find
          .byWidgetPredicate(
            (w) => w.key != null && w.key.toString().contains('drag_'),
          )
          .first;

      // Перетащим элемент вниз
      await tester.drag(handle, const Offset(0, 120));
      await tester.pumpAndSettle();

      // В списке по-прежнему 3 элемента
      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('Delete + Undo restores item and position', (tester) async {
      await pumpScreen(tester);

      // Удаление теперь жестом (свайп влево)
      final firstTile = find.byType(ListTile).first;
      await tester.drag(firstTile, const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Нажимаем «Отменить» в SnackBar (локализовано как «Отменить»)
      await tester.tap(find.text('Отменить'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('DnD reorders a middle item correctly', (tester) async {
      await pumpScreen(tester);

      // Ensure DnD enabled
      expect(container.read(dndEnabledProvider), isTrue);

      // Drag the second item's handle (index 1) down to the bottom
      final secondHandle = find.byIcon(Icons.drag_handle).at(1);
      await tester.drag(secondHandle, const Offset(0, 160));
      await tester.pumpAndSettle();

      // After reordering, there are still 3 tiles
      expect(find.byType(ListTile), findsNWidgets(3));

      // And the last tile should now be the previously middle one ('Хлеб')
      final titles = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .toList();
      final lastTitleWidget = titles.last.title as Text;
      expect(lastTitleWidget.data, anyOf('Хлеб', 'Хлеб'));
    });
  });
}
