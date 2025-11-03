import '../../repositories/items_repository.dart';

class ToggleItemUc {
  final ItemsRepository repo;
  ToggleItemUc(this.repo);
  Future<void> call(int itemId) => repo.toggle(itemId);
}
