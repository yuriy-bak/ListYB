import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listyb/domain/entities/yb_item.dart';
import 'package:listyb/domain/entities/yb_list.dart';
import 'package:listyb/domain/entities/yb_counts.dart';

import 'usecase_providers.dart';

/// Все списки
final listsStreamProvider = StreamProvider.autoDispose<List<YbList>>((ref) {
  final uc = ref.watch(watchListsUcProvider);
  return uc(); // WatchListsUc()
});

/// Элементы списка по listId
final itemsByListStreamProvider = StreamProvider.family
    .autoDispose<List<YbItem>, int>((ref, listId) {
      final uc = ref.watch(watchItemsUcProvider);
      return uc(listId); // WatchItemsUc(listId)
    });

/// Счётчики по конкретному списку
final countsByListProvider = StreamProvider.family.autoDispose<YbCounts, int>((
  ref,
  listId,
) {
  final uc = ref.watch(watchCountsUcProvider);
  return uc(listId);
});
