import 'package:meta/meta.dart';

@immutable
class YbItem {
  final int id;
  final int listId;
  final String title;
  final bool isDone;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  const YbItem({
    required this.id,
    required this.listId,
    required this.title,
    required this.isDone,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  YbItem copyWith({
    String? title,
    bool? isDone,
    int? position,
    DateTime? updatedAt,
    Object? completedAt = _noChange,
  }) {
    return YbItem(
      id: id,
      listId: listId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      position: position ?? this.position,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: identical(completedAt, _noChange)
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }
}

const _noChange = Object();
