import '../../entities/yb_list.dart';
import '../../repositories/lists_repository.dart';

class WatchListsUc {
  final ListsRepository repo;
  WatchListsUc(this.repo);

  Stream<List<YbList>> call({bool includeArchived = false}) =>
      repo.watchAll(includeArchived: includeArchived);
}
