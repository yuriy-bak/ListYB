import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:listyb/di/usecase_providers.dart';

class QuickAddScreen extends ConsumerStatefulWidget {
  final int listId;
  const QuickAddScreen({super.key, required this.listId});

  @override
  ConsumerState<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends ConsumerState<QuickAddScreen> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final addItem = ref.read(addItemUcProvider);
    final text = _controller.text.trim();
    if (text.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await addItem(widget.listId, text);
      if (!mounted) return;
      Navigator.of(context).pop(); // авто‑закрытие
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Быстро добавить')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Новый элемент',
            hintText: 'Введите название...',
          ),
          onSubmitted: (_) => _submit(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _submit,
        child: _saving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.check),
      ),
    );
  }
}
