import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:listyb/di/stream_providers.dart';
import 'package:listyb/di/usecase_providers.dart';

class ListsScreen extends ConsumerWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(listsStreamProvider);
    final createList = ref.watch(createListUcProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ListYB — Lists')),
      body: listsAsync.when(
        data: (lists) {
          if (lists.isEmpty) {
            return const Center(
              child: Text('Пока нет списков.\nСоздайте первый.'),
            );
          }
          return ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, i) {
              final l = lists[i];
              return ListTile(
                title: Text(l.title),
                subtitle: Text('id: ${l.id}'),
                onTap: () => GoRouter.of(context).push('/list/${l.id}'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final controller = TextEditingController();
          final ok = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Создать список'),
                content: TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Название списка',
                  ),
                  onSubmitted: (_) => Navigator.of(context).pop(true),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Отмена'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('ОК'),
                  ),
                ],
              );
            },
          );
          if (ok == true) {
            final title = controller.text.trim();
            if (title.isNotEmpty) {
              await createList(title);
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
