import '../../repositories/items_repository.dart';
import '../../validation/validators.dart';
import '../../entities/yb_item.dart';

class UpdateItemUc {
  final ItemsRepository repo;
  UpdateItemUc(this.repo);

  Future<void> call(YbItem item) {
    validateItemTitle(item.title);
    return repo.update(item);
  }
}
