// lib/domain/validation/validation_errors.dart
class ValidationError implements Exception {
  final String message;
  const ValidationError._(this.message);

  const ValidationError.emptyTitle({required String entity})
    : this._('Empty $entity title is not allowed');

  ValidationError.tooLong({required String entity, required int max})
    : this._('$entity title exceeds $max chars');

  @override
  String toString() => message;
}
