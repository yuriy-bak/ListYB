// lib/features/lists/presentation/lists_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(L10n.t(context, 'home.title')),
            pinned: false,
            floating: true,
            snap: true,
            actions: [
              IconButton(
                tooltip: L10n.t(context, 'common.settings'),
                icon: const Icon(Icons.settings),
                onPressed: () => GoRouter.of(context).push('/settings'),
              ),
              IconButton(
                tooltip: L10n.t(context, 'common.about'),
                icon: const Icon(Icons.info_outline),
                onPressed: () => GoRouter.of(context).push('/about'),
              ),
            ],
          ),
          _BodySliver(listsAsync: listsAsync, countsMapAsync: countsMapAsync),
          SliverToBoxAdapter(
            child: SizedBox(height: 56), // 56 (FAB) + 24 (margin) + запас
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('fab_create_list'),
        heroTag: 'fab_create',
        onPressed: () => _onCreateList(context, ref),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 0.65),
        foregroundColor: Theme.of(
          context,
        ).colorScheme.onPrimary, // контрастная иконка
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

class _BodySliver extends ConsumerWidget {
  const _BodySliver({required this.listsAsync, required this.countsMapAsync});

  final AsyncValue<List<YbList>> listsAsync;
  final AsyncValue<Map<int, YbCounts>> countsMapAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ошибки -> Sliver
    if (listsAsync.hasError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('Error: ${listsAsync.error}')),
      );
    }
    if (countsMapAsync.hasError) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('Error: ${countsMapAsync.error}')),
      );
    }
    // Загрузка -> Sliver
    if (listsAsync.isLoading || countsMapAsync.isLoading) {
      return const _LoadingSliver();
    }

    final lists = listsAsync.value ?? const <YbList>[];
    final countsMap = countsMapAsync.value ?? const <int, YbCounts>{};

    // Пусто -> Sliver
    if (lists.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _Empty(
          onCreate: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(L10n.t(context, 'list.empty'))),
            );
          },
        ),
      );
    }

    // Список -> SliverList
    return _ListSliver(lists: lists, countsMap: countsMap);
  }
}

class _LoadingSliver extends StatelessWidget {
  const _LoadingSliver();

  @override
  Widget build(BuildContext context) {
    return const SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: CircularProgressIndicator()),
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

class _ListSliver extends ConsumerWidget {
  const _ListSliver({required this.lists, required this.countsMap});

  final List<YbList> lists;
  final Map<int, YbCounts> countsMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final list = lists[index];
        final counts = countsMap[list.id];

        Widget card = ListCard(
          list: list,
          counts: counts,
          onTap: () => GoRouter.of(context).go('/list/${list.id}'),
          onLongPressAt: (pos) => _onLongPressAt(context, ref, list, pos),
        );

        return Dismissible(
          key: ValueKey('list_${list.id}'),
          direction: DismissDirection.horizontal,
          background: _SwipeBackground(
            alignment: Alignment.centerLeft,
            color: scheme.errorContainer,
            icon: Icons.delete_outline,
            iconColor: scheme.onErrorContainer,
          ),
          secondaryBackground: _SwipeBackground(
            alignment: Alignment.centerRight,
            color: scheme.primaryContainer,
            icon: Icons.edit_outlined,
            iconColor: scheme.onPrimaryContainer,
          ),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.startToEnd) {
              HapticFeedback.lightImpact();
              final confirmed = await _confirmDeleteWithAutoYes(
                context,
                showCountdownOnButton: true,
              );
              if (confirmed == true) {
                if (!context.mounted) return false;
                final undo = ref.read(undoServiceProvider);
                await undo.deleteWithUndo(context: context, listId: list.id);
                return true; // позволим анимацию удаления
              }
              return false;
            } else if (direction == DismissDirection.endToStart) {
              HapticFeedback.lightImpact();
              await _rename(context, ref, list);
              return false; // переименование без удаления карточки
            }
            return false;
          },
          child: card,
        );
      }, childCount: lists.length),
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
    final confirm = await _confirmDeleteWithAutoYes(
      context,
      showCountdownOnButton: true,
    );
    if (confirm != true) return;
    if (!context.mounted) return;

    final undo = ref.read(undoServiceProvider);
    await undo.deleteWithUndo(context: context, listId: list.id);
  }

  /// Диалог подтверждения удаления (с авто «Да» через 5 сек).
  Future<bool?> _confirmDeleteWithAutoYes(
    BuildContext context, {
    bool showCountdownOnButton = false,
  }) async {
    final completer = Completer<bool?>();
    final navigator = Navigator.of(context);

    Timer? autoTimer;
    Timer? uiTimer;
    int secondsLeft = 5;
    bool decided = false;

    void cleanupTimers() {
      autoTimer?.cancel();
      uiTimer?.cancel();
    }

    void decide(bool result) {
      if (decided) return;
      decided = true;
      cleanupTimers();
      if (!completer.isCompleted) completer.complete(result);
      if (navigator.canPop()) navigator.pop(result);
    }

    autoTimer = Timer(const Duration(seconds: 5), () {
      decide(true); // авто "Да"
    });

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            uiTimer ??= (showCountdownOnButton)
                ? Timer.periodic(const Duration(seconds: 1), (t) {
                    if (secondsLeft > 1) {
                      secondsLeft -= 1;
                      setState(() {});
                    } else {
                      t.cancel();
                    }
                  })
                : null;

            final deleteLabelBase = L10n.t(ctx, 'common.delete');
            final deleteLabel = showCountdownOnButton
                ? '$deleteLabelBase ($secondsLeft)'
                : deleteLabelBase;

            return AlertDialog(
              title: Text(L10n.t(ctx, 'list.delete')),
              content: Text(L10n.t(ctx, 'snackbar.list_deleted')),
              actions: [
                TextButton(
                  onPressed: () => decide(false),
                  child: Text(L10n.t(ctx, 'common.cancel')),
                ),
                TextButton(
                  autofocus: true,
                  onPressed: () => decide(true),
                  child: Text(deleteLabel),
                ),
              ],
            );
          },
        );
      },
    ).then((value) {
      if (!decided && value != null) decide(value);
      cleanupTimers();
      return completer.future;
    });
  }
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.iconColor,
  });

  final Alignment alignment;
  final Color color;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: alignment,
      child: Icon(icon, color: iconColor, size: 24),
    );
  }
}
