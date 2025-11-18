import '../../entities/yb_item.dart';
import '../../repositories/items_repository.dart';

class WatchItemsFilteredUc {
  final ItemsRepository repo;
  WatchItemsFilteredUc(this.repo);

  Stream<List<YbItem>> call(
    int listId, {
    bool? onlyDone,
    bool? onlyActive,
    String? query,
  }) {
    return repo.watchForListFiltered(
      listId,
      onlyDone: onlyDone,
      onlyActive: onlyActive,
      query: query,
    );
  }
}
