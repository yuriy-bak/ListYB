import 'package:drift/drift.dart';
import '../../domain/entities/yb_item.dart';
import '../db/app_database.dart';

extension ItemsRowToEntity on ItemsTableData {
  YbItem toEntity() => YbItem(
    id: id,
    listId: listId,
    title: title,
    isDone: isDone,
    position: position,
    createdAt: createdAt,
    updatedAt: updatedAt,
    completedAt: completedAt,
  );
}

extension YbItemToCompanion on YbItem {
  ItemsTableCompanion toCompanion() => ItemsTableCompanion(
    id: Value(id),
    listId: Value(listId),
    title: Value(title),
    isDone: Value(isDone),
    position: Value(position),
    createdAt: Value(createdAt),
    updatedAt: Value(updatedAt),
    completedAt: Value(completedAt),
  );
}
