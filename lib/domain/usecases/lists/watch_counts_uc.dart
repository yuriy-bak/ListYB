import '../../entities/yb_counts.dart';
import '../../repositories/lists_repository.dart';

class WatchCountsUc {
  final ListsRepository repo;
  WatchCountsUc(this.repo);
  Stream<YbCounts> call(int listId) => repo.watchCounts(listId);
}
