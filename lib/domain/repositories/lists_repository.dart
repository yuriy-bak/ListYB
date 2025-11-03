import '../entities/yb_list.dart';
import '../entities/yb_counts.dart';

abstract class ListsRepository {
  Future<int> create(String title);
  Future<void> rename(int listId, String newTitle);
  Future<void> archive(int listId, {required bool archived});
  Future<void> delete(int listId);

  Stream<List<YbList>> watchAll({bool includeArchived = false});
  Stream<YbList?> watchOne(int listId);

  Stream<Map<int, YbCounts>> watchCountsForAll({bool includeArchived = false});
  Stream<YbCounts> watchCounts(int listId);
}
