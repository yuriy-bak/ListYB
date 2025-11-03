import '../../repositories/lists_repository.dart';
import '../../validation/validators.dart';

class CreateListUc {
  final ListsRepository repo;
  CreateListUc(this.repo);

  Future<int> call(String title) {
    validateListTitle(title);
    return repo.create(title);
  }
}
