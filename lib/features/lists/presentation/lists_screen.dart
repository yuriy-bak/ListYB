import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:listyb/di/stream_providers.dart';
import 'package:listyb/di/usecase_providers.dart';
import 'package:listyb/domain/entities/yb_list.dart';
import 'package:listyb/domain/entities/yb_counts.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(listsStreamProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('ListYB — Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.push('/about'),
          ),
        ],
      ),
      body: listsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Ошибка загрузки списков\n$e'),
          ),
        ),
        data: (lists) {
          if (lists.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            itemCount: lists.length,
            separatorBuilder: (context, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final list = lists[i];
              return _ListTile(list: list);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createListDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _createListDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final createList = ref.read(createListUcProvider);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create list'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'List name'),
          autofocus: true,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;

    try {
      final listId = await createList(name.trim());
      if (!context.mounted) return;
      context.push('/list/$listId');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Не удалось создать список: $e')));
    }
  }
}

class _ListTile extends ConsumerWidget {
  const _ListTile({required this.list});
  final YbList list;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countsAsync = ref.watch(countsByListProvider(list.id));
    return ListTile(
      title: Text(list.title),
      subtitle: countsAsync.when(
        loading: () => const Text('Загрузка…'),
        error: (error, stackTrace) => const Text('—'),
        data: (YbCounts c) => Text('Открытые: ${c.active} / Всего: ${c.total}'),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/list/${list.id}'),
      onLongPress: () => _showListActions(context, ref, list),
    );
  }

  Future<void> _showListActions(
    BuildContext context,
    WidgetRef ref,
    YbList list,
  ) async {
    final rename = ref.read(renameListUcProvider);
    final archive = ref.read(archiveListUcProvider);
    final remove = ref.read(deleteListUcProvider);

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Переименовать'),
              onTap: () => Navigator.of(ctx).pop('rename'),
            ),
            ListTile(
              leading: Icon(list.archived ? Icons.unarchive : Icons.archive),
              title: Text(list.archived ? 'Разархивировать' : 'Архивировать'),
              onTap: () => Navigator.of(ctx).pop('archive'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Удалить'),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;

    try {
      switch (action) {
        case 'rename':
          final controller = TextEditingController(text: list.title);
          final newName = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Переименовать'),
              content: TextField(
                controller: controller,
                autofocus: true,
                onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.of(ctx).pop(controller.text.trim()),
                  child: const Text('Сохранить'),
                ),
              ],
            ),
          );
          if (!context.mounted) return;
          if (newName != null && newName.isNotEmpty) {
            await rename(list.id, newName);
          }
          break;

        case 'archive':
          await archive(list.id, archived: !list.archived);
          break;

        case 'delete':
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Удалить список?'),
              content: Text(
                '«${list.title}» и все его элементы будут удалены.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Удалить'),
                ),
              ],
            ),
          );
          if (!context.mounted) return;
          if (confirm == true) {
            await remove(list.id);
          }
          break;
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Операция не выполнена: $e')));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Пока нет списков.\nСоздайте первый.'));
  }
}
