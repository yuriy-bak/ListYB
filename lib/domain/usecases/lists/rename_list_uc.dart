import '../../repositories/lists_repository.dart';
import '../../validation/validators.dart';

class RenameListUc {
  final ListsRepository repo;
  RenameListUc(this.repo);

  Future<void> call(int id, String newTitle) {
    validateListTitle(newTitle);
    return repo.rename(id, newTitle);
  }
}
