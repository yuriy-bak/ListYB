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

    await tester.pump(); // загрузка
    expect(find.text('Нет списков — создайте первый'), findsOneWidget);
  });

  testWidgets('Список карточек и бейджи open/total', (tester) async {
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
    expect(find.text('3/5'), findsOneWidget);
    expect(find.text('0/0'), findsOneWidget);
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
        onArchive: (listId, archived) {
          calls.add('archive:$listId:$archived');
        },
        onDelete: (listId) {
          calls.add('delete:$listId');
        },
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

    // Долгий тап по карточке (чтобы открыть PopupMenu)
    final tile = find.text('Work');
    expect(tile, findsOneWidget);

    // Получим координату для longPress
    final box = tester.firstRenderObject<RenderBox>(tile);
    final pos = box.localToGlobal(Offset.zero) + const Offset(10, 10);

    await tester.longPressAt(pos);
    await tester.pumpAndSettle();

    // Выбираем "Архивировать" именно в PopupMenuItem
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
        onDelete: (listId) {
          calls.add('delete:$listId');
        },
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

    // Открыть контекстное меню
    final tile = find.text('To delete');
    final box = tester.firstRenderObject<RenderBox>(tile);
    final pos = box.localToGlobal(Offset.zero) + const Offset(10, 10);
    await tester.longPressAt(pos);
    await tester.pumpAndSettle();

    // Нажать "Удалить" в PopupMenuItem
    await tester.tap(find.widgetWithText(PopupMenuItem<ListAction>, 'Удалить'));
    await tester.pumpAndSettle();

    // Диалог: нажать кнопку "Удалить (N)" (а не заголовок)
    final deleteText = find.byWidgetPredicate(
      (w) => w is Text && (w.data?.startsWith('Удалить') ?? false),
    );
    final deleteButton = find.ancestor(
      of: deleteText,
      matching: find.byType(TextButton),
    );
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    // Проверяем, что сервис удаления вызван
    expect(calls, contains('delete:42'));
  });

  testWidgets('Длинный заголовок переносится', (tester) async {
    final longTitle =
        'Очень очень очень длинное название списка, которое должно переноситься на несколько строк без обрезания и троеточий';
    final lists = <YbList>[
      YbList(
        id: 99,
        title: longTitle,
        archived: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sortOrder: 0,
      ),
    ];
    final counts = <int, YbCounts>{
      99: const YbCounts(total: 10, active: 7, done: 3),
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

    await tester.pumpAndSettle();
    final titleFinder = find.text(longTitle);
    expect(titleFinder, findsOneWidget);

    // Проверим, что это Text без ограничения по строкам
    final textWidget = tester.widget<Text>(titleFinder);
    expect(textWidget.maxLines, isNull);
    expect(textWidget.softWrap, isTrue);

    // Высота карточки должна быть больше базовой высоты однострочного айтема
    final cardFinder = find.ancestor(
      of: titleFinder,
      matching: find.byType(Card),
    );
    final size = tester.getSize(cardFinder);
    expect(size.height, greaterThan(72));
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
