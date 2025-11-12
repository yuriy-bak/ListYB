// lib/features/common/undo/undo_snackbar_service.dart
import 'dart:async';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:listyb/l10n/l10n_stub.dart';
import 'package:listyb/di/usecase_providers.dart';
import 'package:listyb/domain/usecases/lists/archive_list_uc.dart';
import 'package:listyb/di/database_providers.dart';
import 'package:listyb/data/db/app_database.dart';

/// Riverpod-провайдер сервиса
final undoServiceProvider = Provider<UndoSnackbarService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final archiveUc = ref.watch(archiveListUcProvider);
  return UndoSnackbarService(db: db, archiveUc: archiveUc);
});

/// Сервис показывает Snackbar и выполняет Undo.
/// Поддерживает один активный job; следующий отменяет предыдущий.
class UndoSnackbarService {
  UndoSnackbarService({
    required AppDatabase db,
    required ArchiveListUc archiveUc,
  }) : _db = db,
       _archiveUc = archiveUc;

  final AppDatabase _db;
  final ArchiveListUc _archiveUc;

  _ActiveJob? _active;

  /// Архив / разархив списка с Undo.
  Future<void> archiveWithUndo({
    required BuildContext context,
    required int listId,
    required bool archived,
  }) async {
    // Готовим messenger и тексты до async-операций, чтобы не держать контекст через async gap.
    final messenger = ScaffoldMessenger.of(context);
    final contentText = L10n.t(
      context,
      archived ? 'snackbar.list_archived' : 'snackbar.list_archived',
    );
    final undoLabel = L10n.t(context, 'snackbar.undo');
    // Применяем действие сразу.
    await _archiveUc(listId, archived: archived);

    // Готовим Snackbar + Undo.
    _cancelActive(); // один активный job
    final job = _ActiveJob(
      kind: _JobKind.archive,
      payload: {'listId': listId, 'archived': archived},
    );
    _active = job;

    final snack = SnackBar(
      duration: const Duration(seconds: 3),
      content: Text(contentText),
      action: SnackBarAction(
        label: undoLabel,
        onPressed: () async {
          if (!_isActive(job)) return;
          // Откат
          await _archiveUc(listId, archived: !archived);
          _clear(job);
        },
      ),
    );

    // После скрытия — очищаем job (если не было Undo).
    final ctrl = messenger.showSnackBar(snack);
    ctrl.closed.then((_) {
      if (_isActive(job)) _clear(job);
    });
  }

  /// Удаление списка с каскадом + Undo восстановления (транзакция).
  Future<void> deleteWithUndo({
    required BuildContext context,
    required int listId,
  }) async {
    // Готовим messenger и тексты до async-операций, чтобы не держать контекст через async gap.
    final messenger = ScaffoldMessenger.of(context);
    final deletedText = L10n.t(context, 'snackbar.list_deleted');
    final undoLabel = L10n.t(context, 'snackbar.undo');
    // 1) Снимем снапшот списка и его элементов.
    final snapshot = await _snapshotList(listId);
    if (snapshot == null) {
      // Нечего удалять.
      return;
    }

    // 2) Удаляем (каскад FK на items).
    await _db.transaction(() async {
      await (_db.delete(
        _db.listsTable,
      )..where((t) => t.id.equals(listId))).go();
    });

    // 3) Показ Snackbar с Undo.
    _cancelActive();
    final job = _ActiveJob(kind: _JobKind.delete, payload: snapshot);
    _active = job;

    final snack = SnackBar(
      duration: const Duration(seconds: 3),
      content: Text(deletedText),
      action: SnackBarAction(
        label: undoLabel,
        onPressed: () async {
          if (!_isActive(job)) return;
          await _restoreSnapshot(snapshot);
          _clear(job);
        },
      ),
    );

    final ctrl = messenger.showSnackBar(snack);
    ctrl.closed.then((_) {
      if (_isActive(job)) _clear(job);
    });
  }

  // --- Вспомогательные методы ---

  void _cancelActive() {
    _active?.dispose();
    _active = null;
  }

  bool _isActive(_ActiveJob job) => identical(_active, job);

  void _clear(_ActiveJob job) {
    if (_isActive(job)) {
      _active?.dispose();
      _active = null;
    }
  }

  /// Снимок одной записи списка + всех элементов (для Undo delete)
  Future<Map<String, Object>?> _snapshotList(int listId) async {
    final listRow = await (_db.select(
      _db.listsTable,
    )..where((t) => t.id.equals(listId))).getSingleOrNull();
    if (listRow == null) return null;

    final itemsRows =
        await (_db.select(_db.itemsTable)
              ..where((t) => t.listId.equals(listId))
              ..orderBy([
                (t) => drift.OrderingTerm.asc(t.position),
                (t) => drift.OrderingTerm.asc(t.id),
              ]))
            .get();

    return {'list': listRow, 'items': itemsRows};
  }

  /// Восстановление списка и его элементов с теми же id (одна транзакция)
  Future<void> _restoreSnapshot(Map<String, Object> snapshot) async {
    final list = snapshot['list'] as ListsTableData;
    final items = (snapshot['items'] as List<ItemsTableData>);

    await _db.transaction(() async {
      // Вставляем список с фиксированным id
      await _db
          .into(_db.listsTable)
          .insert(
            ListsTableCompanion(
              id: drift.Value(list.id),
              title: drift.Value(list.title),
              archived: drift.Value(list.archived),
              sortOrder: drift.Value(list.sortOrder),
              createdAt: drift.Value(list.createdAt),
              updatedAt: drift.Value(list.updatedAt),
            ),
            mode: drift.InsertMode.insertOrAbort,
          );

      // Вставляем все элементы
      for (final it in items) {
        await _db
            .into(_db.itemsTable)
            .insert(
              ItemsTableCompanion(
                id: drift.Value(it.id),
                listId: drift.Value(it.listId),
                title: drift.Value(it.title),
                isDone: drift.Value(it.isDone),
                position: drift.Value(it.position),
                createdAt: drift.Value(it.createdAt),
                updatedAt: drift.Value(it.updatedAt),
                completedAt: drift.Value(it.completedAt),
                note: drift.Value(it.note),
              ),
              mode: drift.InsertMode.insertOrAbort,
            );
      }
    });
  }
}

enum _JobKind { archive, delete }

class _ActiveJob {
  _ActiveJob({required this.kind, required this.payload});
  final _JobKind kind;
  final Object payload;
  void dispose() {}
}
