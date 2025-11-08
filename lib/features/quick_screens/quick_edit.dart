import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:listyb/di/usecase_providers.dart';
import 'package:listyb/domain/entities/yb_item.dart';

class QuickEditScreen extends ConsumerStatefulWidget {
  final int itemId;
  const QuickEditScreen({super.key, required this.itemId});

  @override
  ConsumerState<QuickEditScreen> createState() => _QuickEditScreenState();
}

class _QuickEditScreenState extends ConsumerState<QuickEditScreen> {
  final _controller = TextEditingController();
  bool _saving = false;
  YbItem? _current;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(YbItem old) async {
    if (_saving) return;
    final updateItem = ref.read(updateItemUcProvider);
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      final updated = old.copyWith(title: title, updatedAt: DateTime.now());
      await updateItem(updated);
      if (!mounted) return;
      Navigator.of(context).pop(); // авто-закрытие
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchItem = ref.watch(watchItemUcProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Быстрое редактирование')),
      body: StreamBuilder<YbItem?>(
        stream: watchItem(widget.itemId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final item = snap.data;
          if (item == null) {
            return const Center(child: Text('Элемент не найден'));
          }
          if (_current?.id != item.id) {
            _current = item;
            _controller.text = item.title;
          }
          return Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Название'),
              onSubmitted: (_) async => _save(item),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final item = _current;
          if (item == null) return;
          _save(item);
        },
        child: _saving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check),
      ),
    );
  }
}
