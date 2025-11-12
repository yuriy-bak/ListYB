import 'package:flutter_test/flutter_test.dart';
import 'package:listyb/domain/validation/validators.dart';
import 'package:listyb/domain/validation/validation_errors.dart';

void main() {
  test('list title cannot be empty', () {
    expect(() => validateListTitle('    '), throwsA(isA<ValidationError>()));
  });

  test('item title max length', () {
    final long = 'a' * (kMaxItemTitle + 1);
    expect(() => validateItemTitle(long), throwsA(isA<ValidationError>()));
  });

  test('trim accepted', () {
    expect(() => validateListTitle('  Milk  '), returnsNormally);
  });
}
