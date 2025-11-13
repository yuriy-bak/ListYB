import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:listyb/data/db/app_database.dart';
import 'package:listyb/di/database_providers.dart';
import 'package:listyb/features/lists/application/items_filter.dart';
import 'package:listyb/features/lists/application/watch_list_uc_provider.dart';

class ListDetailsScreen extends ConsumerStatefulWidget {
  const ListDetailsScreen({
    super.key,
    required this.listId,
    this.quickAdd = false,
    this.autoCloseWhenDone = false,
    this.isColdStart = false, // NEW
  });

  final int listId;

  /// Быстрый режим добавления (из диплинка /list/:id?qa=1).
  final bool quickAdd;

  /// Для cold-start QuickAdd: после действия закрыть приложение, если некуда вернуться.
  final bool autoCloseWhenDone;

  /// Признак, что экран открыт холодным стартом (через диплинк)
  /// и маршрут помечен ?cold=1.
  final bool isColdStart; // NEW

  @override
  ConsumerState<ListDetailsScreen> createState() => _ListDetailsScreenState();
}

class _ListDetailsScreenState extends ConsumerState<ListDetailsScreen> {
  final _inputController = TextEditingController();
  final _searchController = TextEditingController();
  final _focus = FocusNode();

  bool? _completedFilter; // null = все, false = активные, true = выполненные
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    if (widget.quickAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openQuickAddDialog();
      });
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _inputController.dispose();
    _searchController.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _setFilter(bool? v) {
    setState(() => _completedFilter = v);
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _addItem() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    final db = ref.read(appDatabaseProvider);
    try {
      await db.itemsDao.createItem(listId: widget.listId, title: text);
      _inputController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Элемент добавлен')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ошибка при добавлении')));
    }
  }

  Future<void> _toggle(ItemsTableData item, bool value) async {
    final db = ref.read(appDatabaseProvider);
    await db.itemsDao.updateItem(id: item.id, completed: value);
  }

  Future<void> _delete(ItemsTableData item) async {
    final db = ref.read(appDatabaseProvider);
    final deleted = item; // копия для Undo
    await db.itemsDao.deleteItem(item.id);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final snack = SnackBar(
      content: const Text('Элемент удалён'),
      action: SnackBarAction(
        label: 'Отменить',
        onPressed: () async {
          final now = DateTime.now();
          await db.itemsDao.insertItem(
            ItemsTableCompanion.insert(
              listId: deleted.listId,
              title: deleted.title,
              createdAt: now,
              updatedAt: now,
              isDone: Value(deleted.isDone),
              position: Value(deleted.position),
              completedAt: Value(deleted.completedAt),
              note: Value(deleted.note),
            ),
          );
        },
      ),
    );
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(snack);
  }

  /// Открывает компактный диалог «Быстро добавить…».
  Future<void> _openQuickAddDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Быстро добавить'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Название элемента',
            isDense: true,
          ),
          onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Добавить'),
          ),
        ],
      ),
    );

    if (!mounted) return;

    if (result != null && result.isNotEmpty) {
      final db = ref.read(appDatabaseProvider);
      try {
        await db.itemsDao.createItem(listId: widget.listId, title: result);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Элемент добавлен')));
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось добавить элемент')),
        );
      }
    }

    // Закрываем сам экран согласно ожиданию UX.
    await _finishQuickAdd();
  }

  /// Закрывает текущий экран (и при необходимости приложение) для QuickAdd.
  Future<void> _finishQuickAdd() async {
    if (!mounted) return;

    final router = GoRouter.of(context);

    if (router.canPop()) {
      // Горячий диплинк: вернёмся на предыдущий экран
      context.pop();
      return;
    }

    // Холодный диплинк QuickAdd: закрыть приложение, если явно указано
    if (widget.autoCloseWhenDone) {
      context.go('/');
      await SystemNavigator.pop();
      return;
    }

    // Если это не QuickAdd‑cold и попать некуда — вернёмся Домой
    context.go('/');
  }

  /// Единая логика системного Back:
  /// - если можем попнуть стек go_router — делаем pop()
  /// - если стек пуст и это холодный старт обычного списка — закрываем приложение
  /// - иначе — идём на Домашний '/'
  Future<void> _handleSystemBack() async {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      context.pop();
      return;
    }

    // Стек пуст.
    // Для обычного "холодного" открытия списка — закрываем приложение.
    // (QuickAdd имеет отдельную логику через autoCloseWhenDone)
    if (widget.isColdStart && !widget.quickAdd) {
      await SystemNavigator.pop();
      return;
    }

    // Во всех остальных корневых случаях — на Домашний.
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(watchListUcProvider(widget.listId));
    final itemsAsync = ref.watch(
      watchItemsByListProvider((
        listId: widget.listId,
        filter: ItemsFilter(
          completed: _completedFilter,
          query: _searchController.text,
        ),
      )),
    );

    return PopScope(
      // ВАЖНО: системный Back всегда идёт через нашу логику
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // если кто-то уже попнул — выходим
        await _handleSystemBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: listAsync.when(
            data: (data) => Text(data?.title ?? 'Список'),
            loading: () => const Text('Загрузка…'),
            error: (error, stackTrace) => const Text('Ошибка'),
          ),
          actions: [
            IconButton(
              tooltip: 'Поиск',
              onPressed: () async {
                await showSearchBar(context);
              },
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        body: Column(
          children: [
            // Быстрое добавление
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      focusNode: _focus,
                      decoration: const InputDecoration(
                        hintText: 'Новый элемент…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addItem(),
                      textInputAction: TextInputAction.done,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ),

            // Фильтры
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: SegmentedButton<bool?>(
                segments: const [
                  ButtonSegment<bool?>(value: null, label: Text('Все')),
                  ButtonSegment<bool?>(value: false, label: Text('Активные')),
                  ButtonSegment<bool?>(value: true, label: Text('Выполненные')),
                ],
                selected: {_completedFilter},
                onSelectionChanged: (s) => _setFilter(s.first),
              ),
            ),

            // Поиск
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Поиск…',
                  isDense: true,
                  border: const OutlineInputBorder(),
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.6),
                  filled: true,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Список
            Expanded(
              child: itemsAsync.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Text('Нет элементов — добавьте первый'),
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (context, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final it = items[index];
                      return Dismissible(
                        key: ValueKey('item_${it.id}'),
                        background: Container(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          color: Colors.red.withValues(alpha: 0.12),
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                        secondaryBackground: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          color: Colors.red.withValues(alpha: 0.12),
                          child: const Icon(Icons.delete, color: Colors.red),
                        ),
                        confirmDismiss: (_) async {
                          await _delete(it);
                          return false;
                        },
                        child: CheckboxListTile(
                          value: it.isDone,
                          onChanged: (v) => _toggle(it, v ?? false),
                          title: Text(
                            it.title,
                            style: it.isDone
                                ? const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                  )
                                : null,
                          ),
                          subtitle: it.note?.isNotEmpty == true
                              ? Text(it.note!)
                              : null,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    const Center(child: Text('Ошибка загрузки элементов')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showSearchBar(BuildContext context) async {
    await Future<void>.delayed(Duration.zero);
    if (!context.mounted) return;
    FocusScope.of(context).requestFocus(_focus);
    await SystemChannels.textInput.invokeMethod('TextInput.show');
  }
}
