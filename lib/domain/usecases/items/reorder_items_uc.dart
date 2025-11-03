import '../../repositories/items_repository.dart';

class ReorderItemsUc {
  final ItemsRepository repo;
  ReorderItemsUc(this.repo);
  Future<void> call(int listId, List<int> orderedIds) =>
      repo.reorder(listId, orderedIds);
}
