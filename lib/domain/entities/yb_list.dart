import 'package:meta/meta.dart';

@immutable
class YbList {
  final int id;
  final String title;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int sortOrder;

  const YbList({
    required this.id,
    required this.title,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
    required this.sortOrder,
  });

  YbList copyWith({
    String? title,
    bool? archived,
    DateTime? updatedAt,
    int? sortOrder,
  }) {
    return YbList(
      id: id,
      title: title ?? this.title,
      archived: archived ?? this.archived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
