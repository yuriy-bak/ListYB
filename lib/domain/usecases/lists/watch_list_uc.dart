import '../../entities/yb_list.dart';
import '../../repositories/lists_repository.dart';

class WatchListUc {
  final ListsRepository repo;
  WatchListUc(this.repo);

  Stream<YbList?> call(int id) => repo.watchOne(id);
}
