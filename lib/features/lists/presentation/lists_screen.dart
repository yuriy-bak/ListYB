import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});
  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final ValueNotifier<List<String>> _lists = ValueNotifier<List<String>>([
    'Demo',
  ]);

  Future<void> _createListDialog() async {
    final controller = TextEditingController();
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
    if (name != null && name.isNotEmpty) {
      final id = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
      final next = [..._lists.value];
      if (!next.contains(name)) next.add(name);
      _lists.value = next;
      if (mounted) context.push('/list/$id');
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: ValueListenableBuilder<List<String>>(
        valueListenable: _lists,
        builder: (context, lists, _) {
          if (lists.isEmpty) return const Center(child: Text('No lists yet'));
          return ListView.separated(
            itemCount: lists.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final name = lists[i];
              final id = name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
              return ListTile(
                title: Text(name),
                subtitle: const Text('placeholder'),
                onTap: () => context.push('/list/$id'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createListDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
