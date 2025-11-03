import '../../entities/yb_item.dart';
import '../../repositories/items_repository.dart';

class WatchItemUc {
  final ItemsRepository repo;
  WatchItemUc(this.repo);
  Stream<YbItem?> call(int id) => repo.watchOne(id);
}
