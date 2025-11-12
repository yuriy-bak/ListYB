import 'package:drift/drift.dart';
import '../../core/clock/clock.dart';
import '../../domain/entities/yb_list.dart';
import '../../domain/entities/yb_counts.dart';
import '../../domain/repositories/lists_repository.dart';
import '../db/app_database.dart';
import '../db/daos/lists_dao.dart';
import '../mappers/list_mappers.dart';
import '../mappers/counts_mappers.dart';

class ListsRepositoryImpl implements ListsRepository {
  final ListsDao _dao;
  final Clock _clock;
  ListsRepositoryImpl(this._dao, this._clock);

  @override
  Future<int> create(String title) {
    final now = _clock.now();
    return _dao.insertList(
      ListsTableCompanion.insert(
        title: title.trim(),
        archived: const Value(false),
        sortOrder: const Value(0),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Future<void> rename(int listId, String newTitle) {
    final now = _clock.now();
    return _dao.updateList(
      listId,
      ListsTableCompanion(title: Value(newTitle.trim()), updatedAt: Value(now)),
    );
  }

  @override
  Future<void> archive(int listId, {required bool archived}) {
    final now = _clock.now();
    return _dao.updateList(
      listId,
      ListsTableCompanion(archived: Value(archived), updatedAt: Value(now)),
    );
  }

  @override
  Future<void> delete(int listId) async {
    await _dao.deleteList(listId); // игнорируем количество удалённых строк
  }

  @override
  Stream<List<YbList>> watchAll({bool includeArchived = false}) => _dao
      .watchAll(includeArchived: includeArchived)
      .map((rows) => rows.map((r) => r.toEntity()).toList());

  @override
  Stream<YbList?> watchOne(int listId) =>
      _dao.watchOne(listId).map((r) => r?.toEntity());

  @override
  Stream<Map<int, YbCounts>> watchCountsForAll({
    bool includeArchived = false,
  }) => _dao
      .watchCountsForAll(includeArchived: includeArchived)
      .map((m) => m.map((k, v) => MapEntry(k, v.toCounts())));

  @override
  Stream<YbCounts> watchCounts(int listId) =>
      _dao.watchCounts(listId).map((v) => v.toCounts());
}
