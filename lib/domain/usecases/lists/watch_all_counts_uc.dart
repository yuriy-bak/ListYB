import '../../entities/yb_counts.dart';
import '../../repositories/lists_repository.dart';

class WatchAllCountsUc {
  final ListsRepository repo;
  WatchAllCountsUc(this.repo);
  Stream<Map<int, YbCounts>> call({bool includeArchived = false}) =>
      repo.watchCountsForAll(includeArchived: includeArchived);
}
