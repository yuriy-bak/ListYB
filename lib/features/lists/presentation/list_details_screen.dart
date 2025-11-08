import 'package:flutter/material.dart';

class ListDetailsScreen extends StatelessWidget {
  final int listId;
  const ListDetailsScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('List: $listId')),
      body: const Center(child: Text('List details — placeholder')),
    );
  }
}
