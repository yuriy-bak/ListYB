import '../../repositories/lists_repository.dart';

class ArchiveListUc {
  final ListsRepository repo;
  ArchiveListUc(this.repo);
  Future<void> call(int id, {required bool archived}) =>
      repo.archive(id, archived: archived);
}
