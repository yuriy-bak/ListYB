import 'validation_errors.dart';

const int kMaxListTitle = 120; // spec: вынести из validation.md при расхождении
const int kMaxItemTitle = 200;

void validateListTitle(String title) {
  final t = title.trim();
  if (t.isEmpty) throw const ValidationError.emptyTitle(entity: 'list');
  if (t.length > kMaxListTitle)
    throw ValidationError.tooLong(entity: 'list', max: kMaxListTitle);
}

void validateItemTitle(String title) {
  final t = title.trim();
  if (t.isEmpty) throw const ValidationError.emptyTitle(entity: 'item');
  if (t.length > kMaxItemTitle)
    throw ValidationError.tooLong(entity: 'item', max: kMaxItemTitle);
}
