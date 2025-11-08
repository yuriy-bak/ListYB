import 'dart:async';
import 'package:drift/drift.dart' show Value; // ← нужен для Value(...)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../di/database_providers.dart'; // ← единый appDatabaseProvider
import '../../lists/application/watch_list_uc_provider.dart';

class ListDetailsScreen extends ConsumerStatefulWidget {
  const ListDetailsScreen({super.key, required this.listId});
  final int listId;

  @override
  ConsumerState<ListDetailsScreen> createState() => _ListDetailsScreenState();
}

class _ListDetailsScreenState extends ConsumerState<ListDetailsScreen> {
  final _inputController = TextEditingController();
  final _searchController = TextEditingController();
  final _focus = FocusNode();

  // Фильтр “все/активные/выполненные”
  bool? _completedFilter; // null = все, false = активные, true = выполненные

  // Дебаунс поиска
  Timer? _searchDebounce;

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
      if (!mounted) {
        return; // не используем context через async gap без проверки
      }
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
      // Безопасно с учетом async gap:
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Элемент добавлен')));
    } on Exception {
      if (!mounted) {
        return;
      }
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

    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final snack = SnackBar(
      content: const Text('Элемент удалён'),
      action: SnackBarAction(
        label: 'Отменить',
        onPressed: () async {
          // Восстановим элемент (позиция может отличаться — R1 ок)
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
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

    return Scaffold(
      appBar: AppBar(
        title: listAsync.when(
          data: (data) => Text(data?.title ?? 'Список'),
          loading: () => const Text('Загрузка…'),
          error: (_, __) => const Text('Ошибка'),
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

          // Переключатели фильтров
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
                // избегаем deprecated withOpacity
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
                  separatorBuilder: (_, __) => const Divider(height: 1),
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
                        // async gap: возвращаем напрямую — без захвата контекста после await
                        await _delete(it);
                        // Элемент удалили сами; запрещаем Dismissible удалять повторно
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
              error: (_, __) =>
                  const Center(child: Text('Ошибка загрузки элементов')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> showSearchBar(BuildContext context) async {
    // Простая UX: фокус в поле поиска, клавиатура вверх.
    await Future<void>.delayed(Duration.zero);
    if (!mounted) {
      return; // защита от async gap
    }
    FocusScope.of(context).requestFocus(_focus);
    await SystemChannels.textInput.invokeMethod('TextInput.show');
  }
}
