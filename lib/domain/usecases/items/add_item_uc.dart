import '../../repositories/items_repository.dart';
import '../../validation/validators.dart';

class AddItemUc {
  final ItemsRepository repo;
  AddItemUc(this.repo);

  Future<int> call(int listId, String title, {int? position}) {
    validateItemTitle(title);
    return repo.add(listId, title, position: position);
  }
}
