import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:listyb/l10n/strings.dart';
import 'package:listyb/domain/entities/yb_item.dart';
import 'package:listyb/di/usecase_providers.dart';
import 'package:listyb/features/lists/presentation/list_details_providers.dart';
import 'package:listyb/features/lists/presentation/widgets/empty_state.dart';
import 'package:listyb/features/lists/presentation/widgets/item_tile.dart';
import 'package:listyb/features/lists/presentation/widgets/quick_add_field.dart';
import 'package:listyb/features/lists/application/items_filter.dart';
import 'package:share_plus/share_plus.dart';

class ListDetailsScreen extends ConsumerStatefulWidget {
  const ListDetailsScreen({
    super.key,
    required this.listId,
    this.quickAdd = false,
    this.autoCloseWhenDone = false,
    this.isColdStart = false,
  });

  final int listId;
  final bool quickAdd;
  final bool autoCloseWhenDone;
  final bool isColdStart;

  @override
  ConsumerState<ListDetailsScreen> createState() => _ListDetailsScreenState();
}

class _ListDetailsScreenState extends ConsumerState<ListDetailsScreen> {
  final _quickAddController = TextEditingController();
  final _searchController = TextEditingController();

  final _quickAddFocus = FocusNode();
  final _searchFocus = FocusNode();

  bool _searchMode = false;

  List<YbItem> _lastAllItems = const [];
  final Map<int, FocusNode> _itemFocus = {};
  FocusNode _focusFor(int id) => _itemFocus.putIfAbsent(id, () => FocusNode());

  @override
  void initState() {
    super.initState();
    if (widget.quickAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusQuickAdd());
    }
  }

  @override
  void dispose() {
    for (final n in _itemFocus.values) {
      n.dispose();
    }
    _quickAddFocus.dispose();
    _searchFocus.dispose();
    _quickAddController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _focusQuickAdd() {}

  Future<void> _onQuickAddSubmitted(String text) async {
    final s = Strings.of(context);
    final addItem = ref.read(addItemUcProvider);
    if (text.trim().isEmpty) return;
    await addItem(widget.listId, text.trim());
    _quickAddController.clear();

    if (widget.autoCloseWhenDone) {
      if (mounted) Navigator.of(context).maybePop();
    } else {
      if (!mounted) return;
      _quickAddFocus.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.commonSave),
          duration: const Duration(milliseconds: 600),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
        ),
      );
    }
  }

  Future<void> _onToggleItem(int itemId) async {
    final toggle = ref.read(toggleItemUcProvider);
    await toggle(itemId);
  }

  Future<void> _onDeleteWithUndo(YbItem item) async {
    final s = Strings.of(context);
    final deleteUc = ref.read(deleteItemUcProvider);
    final addUc = ref.read(addItemUcProvider);
    final reorderUc = ref.read(reorderItemsUcProvider);

    final before = List<YbItem>.from(_lastAllItems);
    final oldIndex = before.indexWhere((e) => e.id == item.id);
    final baseIdsWithout = before
        .where((e) => e.id != item.id)
        .map((e) => e.id)
        .toList();

    await deleteUc(item.id);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        content: Text(s.snackbarItemDeleted),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: s.snackbarUndo,
          onPressed: () async {
            final newId = await addUc(widget.listId, item.title);
            final ids = List<int>.from(baseIdsWithout);
            final insertIndex = (oldIndex < 0)
                ? ids.length
                : oldIndex.clamp(0, ids.length);
            ids.insert(insertIndex, newId);
            await reorderUc(widget.listId, ids);

            if (!mounted) return;
            FocusScope.of(context).unfocus();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _focusFor(newId).requestFocus();
            });
          },
        ),
      ),
    );
  }

  Future<void> _onEditTitle(YbItem item) async {
    final s = Strings.of(context);
    final updateUc = ref.read(updateItemUcProvider);

    final controller = TextEditingController(text: item.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.commonEdit),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: s.itemsAddPlaceholder,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(s.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(s.commonSave),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != item.title) {
      await updateUc(item.copyWith(title: newTitle));
      _focusFor(item.id).requestFocus();
    }
  }

  void _toggleSearchMode(WidgetRef ref, {required bool clearOnExit}) {
    setState(() {
      _searchMode = !_searchMode;
      if (_searchMode) {
        _searchFocus.requestFocus();
      } else {
        if (clearOnExit) {
          _searchController.clear();
          ref.read(itemsQueryProvider(widget.listId).notifier).state = '';
        }
        _searchFocus.unfocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<YbItem>>>(
      allItemsStreamProvider(widget.listId),
      (prev, next) => next.whenData((items) => _lastAllItems = items),
    );

    final itemsAsync = ref.watch(itemsFilteredStreamProvider(widget.listId));
    final dndEnabled = ref.watch(dndEnabledForListProvider(widget.listId));
    final reorderUc = ref.read(reorderItemsUcProvider);
    final listAsync = ref.watch(watchListStreamProvider(widget.listId));

    final s = Strings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final currentFilter = ref.watch(itemsFilterProvider(widget.listId));
    String filterLabel(ItemsFilter f) {
      if (f.completed == true) return s.itemsFilterDone;
      if (f.completed == false) return s.itemsFilterOpen;
      return s.itemsFilterAll;
    }

    final titleWidget = _searchMode
        ? TextField(
            key: const Key('search_field'),
            controller: _searchController,
            focusNode: _searchFocus,
            autofocus: true,
            textInputAction: TextInputAction.search,
            style: theme.textTheme.titleMedium?.copyWith(color: cs.onSurface),
            cursorColor: cs.onSurface,
            decoration: InputDecoration(
              hintText: s.commonSearch,
              hintStyle: theme.textTheme.titleMedium?.copyWith(
                color: cs.onSurface,
              ),
              border: InputBorder.none,
            ),
            onChanged: (text) =>
                ref.read(itemsQueryProvider(widget.listId).notifier).state =
                    text,
          )
        : listAsync.when(
            data: (l) => Text(l?.title ?? ''),
            loading: () => const Text('…'),
            error: (err, stack) => const Text(''),
          );

    return PopScope(
      // Всегда перехватываем системную «Назад», чтобы не закрывать приложение.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        // 1) Если открыт поиск — закрыть и очистить
        if (_searchMode) {
          _toggleSearchMode(ref, clearOnExit: true);
          return;
        }
        // 2) Если есть куда вернуться — обычный pop; иначе — на главный
        final nav = Navigator.of(context);
        if (nav.canPop()) {
          nav.maybePop();
        } else {
          context.go('/');
        }
      },

      child: Scaffold(
        // Переводим экран на NestedScrollView + SliverAppBar с автоскрытием
        body: NestedScrollView(
          // Шапка, которая прячется/появляется при прокрутке
          headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
            SliverAppBar(
              // Принудительно показываем стрелку «Назад»
              automaticallyImplyLeading: false,
              leading: BackButton(
                onPressed: () {
                  final nav = Navigator.of(context);
                  if (nav.canPop()) {
                    nav.maybePop();
                  } else {
                    context.go('/');
                  }
                },
              ),
              title: titleWidget,
              actions: [
                IconButton(
                  key: const Key('search_button'),
                  tooltip: s.commonSearch,
                  icon: Icon(_searchMode ? Icons.close : Icons.search),
                  onPressed: () => _toggleSearchMode(ref, clearOnExit: true),
                ),
                _FilterSelectorAction(
                  key: const Key('filter_selector'),
                  label: filterLabel(currentFilter),
                  onSelected: (a) {
                    final notifier = ref.read(
                      itemsFilterProvider(widget.listId).notifier,
                    );
                    switch (a) {
                      case _FilterAction.all:
                        notifier.state = const ItemsFilter.all();
                        break;
                      case _FilterAction.open:
                        notifier.state = const ItemsFilter.active();
                        break;
                      case _FilterAction.done:
                        notifier.state = const ItemsFilter.done();
                        break;
                    }
                  },
                  itemBuilder: (ctx) {
                    final entries = <PopupMenuEntry<_FilterAction>>[];
                    final current = currentFilter;
                    final currentAction = current.completed == true
                        ? _FilterAction.done
                        : (current.completed == false
                              ? _FilterAction.open
                              : _FilterAction.all);
                    String labelFor(_FilterAction a) => switch (a) {
                      _FilterAction.all => s.itemsFilterAll,
                      _FilterAction.open => s.itemsFilterOpen,
                      _FilterAction.done => s.itemsFilterDone,
                    };
                    for (final a in _FilterAction.values) {
                      final selected = (a == currentAction);
                      entries.add(
                        PopupMenuItem<_FilterAction>(
                          key: Key(
                            a == _FilterAction.all
                                ? 'filter_all'
                                : a == _FilterAction.open
                                ? 'filter_open'
                                : 'filter_done',
                          ),
                          value: a,
                          padding: EdgeInsets.zero,
                          child: Container(
                            decoration: selected
                                ? BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  )
                                : null,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check,
                                  size: 18,
                                  color: selected
                                      ? cs.primary
                                      : Colors.transparent,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  labelFor(a),
                                  style: selected
                                      ? TextStyle(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return entries;
                  },
                ),
                // ✅ Кнопка «Поделиться»
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: s.commonShare,
                  onPressed: () async {
                    final list = listAsync.value;
                    final items = _lastAllItems;
                    if (list == null || items.isEmpty) return;
                    final shareText = _generateShareMarkdownText(list.title, items);
                    await SharePlus.instance.share(
                      ShareParams(text: shareText),
                    );
                  },
                ),
              ],
              // Ключевые флаги для автоскрытия
              floating: true,
              snap: true,
              // Переносим QuickAdd в низ шапки, чтобы он скрывался вместе с AppBar
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(64),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: QuickAddField(
                      controller: _quickAddController,
                      focusNode: _quickAddFocus,
                      textFieldKey: const Key('quick_add_field'),
                      hintText: s.itemsAddPlaceholder,
                      onSubmitted: _onQuickAddSubmitted,
                      // Автофокус сохранён — поле получает фокус при открытии экрана,
                      // но теперь находится в шапке и будет скрываться/появляться с ней.
                      autofocus: widget.quickAdd,
                    ),
                  ),
                ),
              ),

              // (не делаем pinned, чтобы шапка полностью исчезала)
              elevation: 0,
            ),
          ],

          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: itemsAsync.when(
                    data: (items) {
                      if (items.isEmpty) return const EmptyState();

                      Future<void> onReorder(int oldIndex, int newIndex) async {
                        final ids = items.map((e) => e.id).toList();
                        if (newIndex > oldIndex) newIndex -= 1;
                        final moved = ids.removeAt(oldIndex);
                        ids.insert(newIndex, moved);
                        await reorderUc(widget.listId, ids);
                      }

                      Widget buildRow(int index) {
                        final it = items[index];

                        return Dismissible(
                          key: ValueKey('dismiss_${it.id}'),
                          direction: DismissDirection.horizontal,
                          background: _SwipeBackground(
                            alignment: Alignment.centerLeft,
                            color: Colors.red.shade50,
                            icon: Icons.delete,
                            iconColor: Colors.red,
                          ),
                          secondaryBackground: _SwipeBackground(
                            alignment: Alignment.centerRight,
                            color: Colors.blue.shade50,
                            icon: Icons.edit,
                            iconColor: Colors.blue,
                          ),
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.endToStart) {
                              await _onEditTitle(it);
                              return false;
                            } else {
                              return true; // delete
                            }
                          },
                          onDismissed: (direction) {
                            if (direction == DismissDirection.startToEnd) {
                              _onDeleteWithUndo(it);
                            }
                          },
                          child: Material(
                            key: ValueKey('item_${it.id}'),
                            child: ItemTile(
                              item: it,
                              itemIndex: index,
                              dndEnabled: dndEnabled,
                              onToggle: () => _onToggleItem(it.id),
                              onDelete: () => _onDeleteWithUndo(it),
                              focusNode: _focusFor(it.id),
                            ),
                          ),
                        );
                      }

                      if (dndEnabled) {
                        return ReorderableListView.builder(
                          buildDefaultDragHandles: false,
                          itemCount: items.length,
                          onReorder: onReorder,
                          itemBuilder: (context, index) => buildRow(index),
                        );
                      } else {
                        return ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) => buildRow(index),
                        );
                      }
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text(e.toString())),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Генерация текста для «Поделиться»
  String _generateShareMarkdownText(String listTitle, List<YbItem> items) {
    final buffer = StringBuffer();
    buffer.writeln('# $listTitle\n');
    for (final item in items) {
      final status = item.isDone ? '[x]' : '[ ]';
      buffer.writeln('- $status ${item.title}');
    }
    return buffer.toString();
  }
}

enum _FilterAction { all, open, done }

class _FilterSelectorAction extends StatelessWidget {
  const _FilterSelectorAction({
    super.key,
    required this.label,
    required this.onSelected,
    required this.itemBuilder,
  });

  final String label;
  final ValueChanged<_FilterAction> onSelected;
  final PopupMenuItemBuilder<_FilterAction> itemBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return PopupMenuButton<_FilterAction>(
      onSelected: onSelected,
      itemBuilder: itemBuilder,
      offset: const Offset(0, kToolbarHeight),
      tooltip: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(color: onSurface),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: onSurface),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
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
