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
import 'list_share_import.dart';

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
  bool _importInProgress = false;

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

  Future<void> _showImportDialog() async {
    if (_importInProgress) return;
    final s = Strings.of(context);
    bool replaceTitle = true;
    bool clearBefore = false;
    final textCtrl = TextEditingController();

    final markdown = await showDialog<String>(
      context: context,

      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Импорт из Markdown'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtrl,
                autofocus: true,
                maxLines: 12,
                minLines: 6,
                decoration: const InputDecoration(
                  hintText:
                      '# Заголовок\n- [ ] Элемент\n\nАбзац без маркера → элемент (не выполнен)',
                  border: OutlineInputBorder(),
                ),
              ),
              // const SizedBox(height: 12),
              CheckboxListTile(
                value: replaceTitle,
                onChanged: (v) => setState(() => replaceTitle = v ?? true),
                title: const Text(
                  'Заменить название списка заголовком из Markdown',
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              CheckboxListTile(
                value: clearBefore,
                onChanged: (v) => setState(() => clearBefore = v ?? false),
                title: const Text('Очистить текущие элементы перед импортом'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(s.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(textCtrl.text),
              child: const Text('Импорт'),
            ),
          ],
        ),
      ),
    );

    if (markdown == null || markdown.trim().isEmpty) return;
    final parsed = parseShareMarkdown(markdown);

    if (parsed.hasMultipleLists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'В файле обнаружено несколько заголовков списков.\nТекущая версия поддерживает только один список.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final addUc = ref.read(addItemUcProvider);
    final toggleUc = ref.read(toggleItemUcProvider);
    setState(() => _importInProgress = true);
    try {
      if (clearBefore && _lastAllItems.isNotEmpty) {
        final deleteUc = ref.read(deleteItemUcProvider);
        for (final it in _lastAllItems) {
          await deleteUc(it.id);
        }
      }

      for (final it in parsed.items) {
        final newId = await addUc(widget.listId, it.title);
        if (it.isDone) await toggleUc(newId);
      }

      if (replaceTitle && parsed.hasTitle) {
        final renameList = ref.read(renameListUcProvider);
        await renameList(widget.listId, parsed.title!);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Импортировано: ${parsed.items.length}')),
      );
    } finally {}
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
    final countsAsync = ref.watch(watchCountsProvider(widget.listId));

    final s = Strings.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final currentFilter = ref.watch(itemsFilterProvider(widget.listId));
    String filterLabel(ItemsFilter f) {
      if (f.completed == true) return s.itemsFilterDone;
      if (f.completed == false) return s.itemsFilterOpen;
      return s.itemsFilterAll;
    }

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
        body: NestedScrollView(
          headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
            SliverAppBar(
              // Принудительно показываем стрелку «Назад»
              automaticallyImplyLeading: false,
              toolbarHeight: 44,
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
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  listAsync.when(
                    data: (l) => Text(l?.title ?? ''),
                    loading: () => const Text('…'),
                    error: (e, _) => const Text(''),
                  ),
                  countsAsync.when(
                    data: (c) => Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${c.active}',
                            style: TextStyle(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const TextSpan(text: ' / '),
                          TextSpan(
                            text: '${c.total}',
                            style: TextStyle(
                              color: cs.onSurfaceVariant,
                              fontSize: 16,
                            ),
                          ),
                        ],
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (e, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
              actions: [],
              // Ключевые флаги для автоскрытия
              floating: false,
              snap: false,
              pinned: true,
              elevation: 0,
            ),

            SliverToBoxAdapter(
              child: _FixedHeader(
                searchController: _searchController,
                searchFocus: _searchFocus,
                onSearchChanged: (text) =>
                    ref.read(itemsQueryProvider(widget.listId).notifier).state =
                        text,
                searchHint: s.commonSearch,
                filterLabel: filterLabel(currentFilter),
                onFilterSelected: (a) {
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
                onShare: () async {
                  final list = listAsync.value;
                  final items = _lastAllItems;
                  if (list == null || items.isEmpty) return;
                  final shareText = generateShareMarkdownText(
                    list.title,
                    items,
                  );
                  await SharePlus.instance.share(ShareParams(text: shareText));
                },
                onImport: _showImportDialog,
                quickAddController: _quickAddController,
                quickAddFocus: _quickAddFocus,
                onQuickAddSubmitted: _onQuickAddSubmitted,
                quickAddHint: s.itemsAddPlaceholder,
                quickAddAutofocus: widget.quickAdd,
              ),
            ),
          ],

          body: Padding(
            padding: const EdgeInsets.all(0),
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
                          child: ItemTile(
                            item: it,
                            itemIndex: index,
                            dndEnabled: dndEnabled,
                            onToggle: () => _onToggleItem(it.id),
                            onDelete: () => _onDeleteWithUndo(it),
                            focusNode: _focusFor(it.id),
                          ),
                        );
                      }

                      if (dndEnabled) {
                        return ReorderableListView.builder(
                          itemCount: items.length,
                          onReorder: onReorder,
                          // 🔦 Подсветка перетаскиваемого элемента
                          proxyDecorator:
                              (
                                Widget child,
                                int index,
                                Animation<double> anim,
                              ) {
                                final curved = CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOut,
                                );
                                return ScaleTransition(
                                  scale: Tween(
                                    begin: 1.0,
                                    end: 1.03,
                                  ).animate(curved),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x13000000),
                                          blurRadius: 12,
                                          spreadRadius: 2,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.6),
                                        width: 2,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                          itemBuilder: (context, index) {
                            final it = items[index];
                            return ReorderableDelayedDragStartListener(
                              key: ValueKey('item_${it.id}'),
                              index: index,
                              child: buildRow(
                                index,
                              ), // внутри уже Dismissible + ItemTile
                            );
                          },
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
}

enum _FilterAction { all, open, done }

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

class _FixedHeader extends StatelessWidget {
  const _FixedHeader({
    required this.searchController,
    required this.searchFocus,
    required this.onSearchChanged,
    required this.searchHint,
    required this.filterLabel,
    required this.onFilterSelected,
    required this.onShare,
    required this.onImport,
    required this.quickAddController,
    required this.quickAddFocus,
    required this.onQuickAddSubmitted,
    required this.quickAddHint,
    required this.quickAddAutofocus,
  });

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final ValueChanged<String> onSearchChanged;
  final String searchHint;
  final String filterLabel;
  final ValueChanged<_FilterAction> onFilterSelected;
  final VoidCallback onShare;
  final VoidCallback onImport;
  final TextEditingController quickAddController;
  final FocusNode quickAddFocus;
  final ValueChanged<String> onQuickAddSubmitted;
  final String quickAddHint;
  final bool quickAddAutofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('search_field'),
                    controller: searchController,
                    focusNode: searchFocus,
                    minLines: 1,
                    maxLines: 1,
                    textAlignVertical: TextAlignVertical.center,
                    textInputAction: TextInputAction.search,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onSurface,
                    ),
                    cursorColor: cs.onSurface,
                    decoration: InputDecoration(
                      hintText: searchHint,
                      hintStyle: theme.textTheme.titleMedium?.copyWith(
                        color: cs.onSurface,
                      ),
                      border: UnderlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                IconButton(
                  key: const Key('search_button'),
                  tooltip: searchHint,
                  icon: Icon(
                    searchController.text.isNotEmpty
                        ? Icons.close
                        : Icons.search,
                  ),
                  onPressed: () {
                    if (searchController.text.isNotEmpty) {
                      searchController.clear();
                      onSearchChanged('');
                    } else {
                      searchFocus.requestFocus();
                    }
                  },
                ),
                PopupMenuButton<_FilterAction>(
                  tooltip: filterLabel,
                  onSelected: onFilterSelected,
                  itemBuilder: (ctx) => const [
                    PopupMenuItem<_FilterAction>(
                      value: _FilterAction.all,
                      child: Text('Все'),
                    ),
                    PopupMenuItem<_FilterAction>(
                      value: _FilterAction.open,
                      child: Text('Открытые'),
                    ),
                    PopupMenuItem<_FilterAction>(
                      value: _FilterAction.done,
                      child: Text('Выполненные'),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        Text(
                          filterLabel,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, color: cs.onSurface),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Поделиться',
                  onPressed: onShare,
                ),
                PopupMenuButton<int>(
                  tooltip: 'Меню',
                  onSelected: (_) => onImport(),
                  itemBuilder: (ctx) => const [
                    PopupMenuItem<int>(value: 1, child: Text('Импорт')),
                  ],
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 8),
            QuickAddField(
              controller: quickAddController,
              focusNode: quickAddFocus,
              textFieldKey: const Key('quick_add_field'),
              hintText: quickAddHint,
              onSubmitted: onQuickAddSubmitted,
              autofocus: quickAddAutofocus,
            ),
          ],
        ),
      ),
    );
  }
}
