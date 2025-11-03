import '../../entities/yb_item.dart';
import '../../repositories/items_repository.dart';

class WatchItemsUc {
  final ItemsRepository repo;
  WatchItemsUc(this.repo);

  Stream<List<YbItem>> call(int listId, {bool? onlyDone, bool? onlyActive}) =>
      repo.watchForList(listId, onlyDone: onlyDone, onlyActive: onlyActive);
}
