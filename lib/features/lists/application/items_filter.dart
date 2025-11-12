// lib/features/lists/application/items_filter.dart
import 'package:flutter/foundation.dart';

/// Три состояния по выполненности:
///   completed == true  -> только выполненные
///   completed == false -> только активные
///   completed == null  -> все
@immutable
class ItemsFilter {
  final String? query;
  final bool? completed;

  const ItemsFilter({this.query, this.completed});

  ItemsFilter copyWith({String? query, bool? completed}) {
    return ItemsFilter(
      query: query ?? this.query,
      completed: completed ?? this.completed,
    );
  }

  /// Удобные пресеты
  const ItemsFilter.all({String? query}) : this(query: query, completed: null);
  const ItemsFilter.active({String? query})
    : this(query: query, completed: false);
  const ItemsFilter.done({String? query}) : this(query: query, completed: true);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemsFilter &&
        other.query == query &&
        other.completed == completed;
  }

  @override
  int get hashCode => Object.hash(query, completed);

  @override
  String toString() => 'ItemsFilter(query: $query, completed: $completed)';
}
