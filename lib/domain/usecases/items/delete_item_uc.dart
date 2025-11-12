import '../../repositories/items_repository.dart';

class DeleteItemUc {
  final ItemsRepository repo;
  DeleteItemUc(this.repo);
  Future<void> call(int id) => repo.delete(id);
}
