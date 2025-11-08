import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listyb/data/db/app_database.dart';
import 'package:listyb/di/database_providers.dart';
import 'package:listyb/features/lists/application/watch_list_uc_provider.dart';
import 'package:listyb/features/lists/application/items_filter.dart';
import 'package:go_router/go_router.dart';

class ListDetailsScreen extends ConsumerStatefulWidget {
  const ListDetailsScreen({
    super.key,
    required this.listId,
    this.quickAdd = false,
    this.autoCloseWhenDone = false,
  });

  final int listId;

  /// Быстрый режим добавления (из диплинка /list/:id/add)
  final bool quickAdd;

  /// Для cold-start QuickAdd: после действия закрыть приложение, если некуда вернуться.
  final bool autoCloseWhenDone;

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

    // Если пришли по диплинку QuickAdd — сразу открываем компактный диалог.
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
    } on Exception {
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
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(snack);
  }

  /// Открывает компактный диалог «Быстро добавить…».
  Future<void> _openQuickAddDialog() async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Быстро добавить'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Название элемента',
            isDense: true,
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
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

    // Закрываем сам экран, т.к. это QuickAdd-вызов.
    _finishQuickAdd();
  }

  /// Закрывает текущий экран (и при необходимости приложение).
  Future<void> _finishQuickAdd() async {
    if (!mounted) return;

    // Если есть куда вернуться — просто попнем текущий маршрут.
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    // Если это cold-start QuickAdd и некуда попать — закрываем приложение.
    if (widget.autoCloseWhenDone) {
      await SystemNavigator.pop();
    }
  }

  /// Локальная логика системной кнопки «Назад»:
  /// если экран открыт как корневой (некуда попать) — идём на домашний '/',
  /// иначе — обычный pop().
  Future<bool> _handleSystemBack() async {
    // В go_router есть extension: context.canPop(), но проверим более совместимо.
    final canPop = Navigator.of(context).canPop();
    if (canPop) return true;
    if (!mounted) return false;
    context.go('/'); // подменяем закрытие приложения на переход «домой»
    return false; // самим pop не выполняем
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
      canPop: true,
      onPopInvoked: (didPop) async {
        // Если уже попнули — ничего не делаем. Если нет — пробуем наша логика.
        if (didPop) return;
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
            // Быстрое добавление (обычный режим)
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

            // Поисковая строка
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

            // Список элементов
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
                          // удаляем вручную + показываем Undo
                          await _delete(it);
                          return false; // Dismissible не удаляет повторно
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
    if (!context.mounted) return; // важно: проверяем контекст
    FocusScope.of(context).requestFocus(_focus);
    await SystemChannels.textInput.invokeMethod('TextInput.show');
  }
}
