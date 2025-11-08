import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';

import 'package:listyb/domain/usecases/lists/create_list_uc.dart';
import 'package:listyb/domain/usecases/lists/rename_list_uc.dart';
import 'package:listyb/domain/usecases/lists/archive_list_uc.dart';
import 'package:listyb/domain/usecases/lists/delete_list_uc.dart';
import 'package:listyb/domain/usecases/lists/watch_lists_uc.dart';
import 'package:listyb/domain/usecases/lists/watch_counts_uc.dart';

import 'package:listyb/domain/usecases/items/add_item_uc.dart';
import 'package:listyb/domain/usecases/items/update_item_uc.dart';
import 'package:listyb/domain/usecases/items/delete_item_uc.dart';
import 'package:listyb/domain/usecases/items/reorder_items_uc.dart';
import 'package:listyb/domain/usecases/items/toggle_item_uc.dart';
import 'package:listyb/domain/usecases/items/watch_items_uc.dart';
import 'package:listyb/domain/usecases/items/watch_item_uc.dart';

// Lists
final createListUcProvider = Provider<CreateListUc>((ref) {
  final repo = ref.watch(listsRepositoryProvider);
  return CreateListUc(repo);
});
final renameListUcProvider = Provider<RenameListUc>((ref) {
  final repo = ref.watch(listsRepositoryProvider);
  return RenameListUc(repo);
});
final archiveListUcProvider = Provider<ArchiveListUc>((ref) {
  final repo = ref.watch(listsRepositoryProvider);
  return ArchiveListUc(repo);
});
final deleteListUcProvider = Provider<DeleteListUc>((ref) {
  final repo = ref.watch(listsRepositoryProvider);
  return DeleteListUc(repo);
});
final watchListsUcProvider = Provider<WatchListsUc>((ref) {
  final repo = ref.watch(listsRepositoryProvider);
  return WatchListsUc(repo);
});
final watchCountsUcProvider = Provider<WatchCountsUc>((ref) {
  final repo = ref.watch(listsRepositoryProvider);
  return WatchCountsUc(repo);
});

// Items
final addItemUcProvider = Provider<AddItemUc>((ref) {
  final repo = ref.watch(itemsRepositoryProvider);
  return AddItemUc(repo);
});
final updateItemUcProvider = Provider<UpdateItemUc>((ref) {
  final repo = ref.watch(itemsRepositoryProvider);
  return UpdateItemUc(repo);
});
final deleteItemUcProvider = Provider<DeleteItemUc>((ref) {
  final repo = ref.watch(itemsRepositoryProvider);
  return DeleteItemUc(repo);
});
final reorderItemsUcProvider = Provider<ReorderItemsUc>((ref) {
  final repo = ref.watch(itemsRepositoryProvider);
  return ReorderItemsUc(repo);
});
final toggleItemUcProvider = Provider<ToggleItemUc>((ref) {
  final repo = ref.watch(itemsRepositoryProvider);
  return ToggleItemUc(repo);
});
final watchItemsUcProvider = Provider<WatchItemsUc>((ref) {
  final repo = ref.watch(itemsRepositoryProvider);
  return WatchItemsUc(repo);
});
final watchItemUcProvider = Provider<WatchItemUc>((ref) {
  final repo = ref.watch(itemsRepositoryProvider);
  return WatchItemUc(repo);
});
