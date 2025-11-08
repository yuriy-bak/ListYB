import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/db/app_database.dart';

/// Единый провайдер AppDatabase.
/// В R1 храним всё локально, для простоты используем in-memory или файл позже.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  // На R1 можно оставить in-memory. Если нужен файл — подключим ffi/путь.
  return makeInMemoryDb();
});
