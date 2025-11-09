// lib/features/lists/presentation/lists_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import 'package:listyb/l10n/l10n_stub.dart';
import 'package:listyb/domain/entities/yb_list.dart';
import 'package:listyb/domain/entities/yb_counts.dart';

import 'package:listyb/di/stream_providers.dart';
import 'package:listyb/di/usecase_providers.dart';
import 'package:listyb/features/common/undo/undo_snackbar_service.dart';

import 'widgets/list_card.dart';
import 'widgets/list_actions_menu.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(listsStreamProvider);
    final countsMapAsync = ref.watch(countsForAllStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.t(context, 'app.title')),
        actions: [
          IconButton(
            tooltip: L10n.t(context, 'common.settings'),
            icon: const Icon(Icons.settings),
            onPressed: () => GoRouter.of(context).go('/settings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onCreateList(context, ref),
        icon: const Icon(Icons.add),
        label: Text(L10n.t(context, 'list.create')),
      ),
      body: _Body(listsAsync: listsAsync, countsMapAsync: countsMapAsync),
    );
  }

  Future<void> _onCreateList(BuildContext context, WidgetRef ref) async {
    final uc = ref.read(createListUcProvider);
    final title = await _askText(
      context: context,
      title: L10n.t(context, 'list.create'),
      initial: '',
    );
    if (title == null) return;
    try {
      await uc(title);
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, e);
    }
  }

  static Future<String?> _askText({
    required BuildContext context,
    required String title,
    required String initial,
  }) async {
    final controller = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.of(ctx).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(L10n.t(ctx, 'common.cancel')),
          ),
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(L10n.t(ctx, 'common.save')),
          ),
        ],
      ),
    );
  }

  static void _showError(BuildContext context, Object e) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.listsAsync, required this.countsMapAsync});

  final AsyncValue<List<YbList>> listsAsync;
  final AsyncValue<Map<int, YbCounts>> countsMapAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ошибки
    if (listsAsync.hasError) {
      return Center(child: Text('Error: ${listsAsync.error}'));
    }
    if (countsMapAsync.hasError) {
      return Center(child: Text('Error: ${countsMapAsync.error}'));
    }
    // Загрузка
    if (listsAsync.isLoading || countsMapAsync.isLoading) {
      return const _Loading();
    }
    final lists = listsAsync.value ?? const <YbList>[];
    final countsMap = countsMapAsync.value ?? const <int, YbCounts>{};
    if (lists.isEmpty) {
      return _Empty(
        onCreate: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(L10n.t(context, 'list.empty'))),
          );
        },
      );
    }
    return _ListView(lists: lists, countsMap: countsMap);
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    // Лёгкий скелетон/лоадер
    return ListView.builder(
      itemCount: 6,
      itemBuilder: (context, i) => const ListTile(
        leading: CircleAvatar(),
        title: SizedBox(
          height: 16,
          child: DecoratedBox(decoration: BoxDecoration(color: Colors.black12)),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(L10n.t(context, 'list.empty')));
  }
}

class _ListView extends ConsumerWidget {
  const _ListView({required this.lists, required this.countsMap});

  final List<YbList> lists;
  final Map<int, YbCounts> countsMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: lists.length,
      itemBuilder: (context, index) {
        final list = lists[index];
        final counts = countsMap[list.id];
        return ListCard(
          list: list,
          counts: counts,
          onTap: () => GoRouter.of(context).go('/list/${list.id}'),
          onLongPressAt: (pos) => _onLongPressAt(context, ref, list, pos),
        );
      },
    );
  }

  Future<void> _onLongPressAt(
    BuildContext context,
    WidgetRef ref,
    YbList list,
    Offset pos,
  ) async {
    final action = await showListContextMenu(
      context: context,
      globalPosition: pos,
      list: list,
    );
    if (action == null) return;
    if (!context.mounted) return;

    switch (action) {
      case ListAction.rename:
        await _rename(context, ref, list);
        break;
      case ListAction.archive:
        await _archive(context, ref, list, archived: true);
        break;
      case ListAction.unarchive:
        await _archive(context, ref, list, archived: false);
        break;
      case ListAction.delete:
        await _delete(context, ref, list);
        break;
    }
  }

  Future<void> _rename(BuildContext context, WidgetRef ref, YbList list) async {
    final title = await ListsScreen._askText(
      context: context,
      title: L10n.t(context, 'list.rename'),
      initial: list.title,
    );
    if (title == null || title.trim().isEmpty) return;
    final uc = ref.read(renameListUcProvider);
    try {
      await uc(list.id, title);
    } catch (e) {
      if (!context.mounted) return;
      ListsScreen._showError(context, e);
    }
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    YbList list, {
    required bool archived,
  }) async {
    final undo = ref.read(undoServiceProvider);
    await undo.archiveWithUndo(
      context: context,
      listId: list.id,
      archived: archived,
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, YbList list) async {
    final confirm = await _confirmDeleteWithAutoYes(context);
    if (confirm != true) return;
    if (!context.mounted) return;

    final undo = ref.read(undoServiceProvider);
    await undo.deleteWithUndo(context: context, listId: list.id);
  }

  /// Диалог подтверждения удаления:
  /// - Кнопка по умолчанию "Да" (autofocus).
  /// - Авто-подтверждение через 5 сек, если нет действий.
  /// - Возвращает true/false.
  Future<bool?> _confirmDeleteWithAutoYes(BuildContext context) async {
    final completer = Completer<bool?>();
    final navigator = Navigator.of(context);

    Timer? timer;
    bool decided = false;

    void decide(bool result) {
      if (decided) return;
      decided = true;
      timer?.cancel();
      if (!completer.isCompleted) completer.complete(result);
      if (navigator.canPop()) navigator.pop(result);
    }

    timer = Timer(const Duration(seconds: 5), () {
      decide(true); // авто "Да"
    });

    // Показ диалога
    showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: Text(L10n.t(ctx, 'list.delete')),
          content: Text(L10n.t(ctx, 'snackbar.list_deleted')),
          actions: [
            TextButton(
              onPressed: () => decide(false),
              child: Text(L10n.t(ctx, 'common.cancel')),
            ),
            TextButton(
              autofocus: true, // кнопка по умолчанию
              onPressed: () => decide(true),
              child: Text(L10n.t(ctx, 'common.delete')),
            ),
          ],
        );
      },
    ).then((value) {
      // Если диалог закрыли через barrier/back — решает таймер,
      // либо сюда прилетит значение. В обеих случаях решает decide().
      if (!decided && value != null) decide(value);
    });

    return completer.future;
  }
}
