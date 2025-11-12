import '../../repositories/lists_repository.dart';

class DeleteListUc {
  final ListsRepository repo;
  DeleteListUc(this.repo);
  Future<void> call(int id) => repo.delete(id);
}
