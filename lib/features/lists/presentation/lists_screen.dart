import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

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
      body: ListView(
        children: [
          ListTile(
            title: const Text('Demo'),
            subtitle: const Text('2 items, 1 done'),
            onTap: () => context.push('/list/demo'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Create list — coming soon')),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
