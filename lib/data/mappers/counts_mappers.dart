import '../../domain/entities/yb_counts.dart';

extension TupleToCounts on ({int total, int active, int done}) {
  YbCounts toCounts() => YbCounts(total: total, active: active, done: done);
}
