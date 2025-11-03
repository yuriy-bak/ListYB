import 'package:drift/drift.dart';
import '../../domain/entities/yb_list.dart';
import '../db/app_database.dart';

extension ListsRowToEntity on ListsTableData {
  YbList toEntity() => YbList(
    id: id,
    title: title,
    archived: archived,
    sortOrder: sortOrder,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

extension YbListToCompanion on YbList {
  ListsTableCompanion toCompanion() => ListsTableCompanion(
    id: Value(id),
    title: Value(title),
    archived: Value(archived),
    sortOrder: Value(sortOrder),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
  );
}
