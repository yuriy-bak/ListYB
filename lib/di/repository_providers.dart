// lib/di/repository_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:listyb/core/clock/clock.dart';

// Доменные интерфейсы:
import 'package:listyb/domain/repositories/lists_repository.dart';
import 'package:listyb/domain/repositories/items_repository.dart';

// Реализации:
import 'package:listyb/data/repositories/lists_repository_impl.dart';
// ItemsRepositoryImpl добавь по твоему пути (в прошлых ссылках он был):
import 'package:listyb/data/repositories/items_repository_impl.dart';

import 'database_providers.dart';

// Системные часы как зависимость домена/репозиториев
final clockProvider = Provider<Clock>((ref) => const SystemClock());

final listsRepositoryProvider = Provider<ListsRepository>((ref) {
  final listsDao = ref.watch(listsDaoProvider);
  final clock = ref.watch(clockProvider);
  return ListsRepositoryImpl(listsDao, clock);
});

final itemsRepositoryProvider = Provider<ItemsRepository>((ref) {
  final itemsDao = ref.watch(itemsDaoProvider);
  final db = ref.watch(appDatabaseProvider);
  final clock = ref.watch(clockProvider);
  return ItemsRepositoryImpl(itemsDao, db, clock);
});
