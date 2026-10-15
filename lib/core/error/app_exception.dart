/// Base type for expected, user-presentable failures.
///
/// Unexpected programming errors are not wrapped; they propagate normally.
sealed class AppException implements Exception {
  const AppException();
}

/// Reasons a deck cannot be created or saved.
enum DeckValidationError {
  nameEmpty,
  nameTooLong,
  nameDuplicate,
  dailyLimitOutOfRange,
  unsupportedLanguage,
  identicalLanguages,
}

final class DeckValidationException extends AppException {
  const DeckValidationException(this.errors);

  final Set<DeckValidationError> errors;

  @override
  String toString() => 'DeckValidationException($errors)';
}

/// A requested record does not exist.
final class NotFoundException extends AppException {
  const NotFoundException(this.entity, this.id);

  final String entity;
  final String id;

  @override
  String toString() => 'NotFoundException($entity, $id)';
}

/// The local database failed. [cause] is kept for diagnostics only and must
/// not be shown to users verbatim.
final class StorageException extends AppException {
  const StorageException(this.operation, this.cause, [this.stackTrace]);

  final String operation;
  final Object cause;
  final StackTrace? stackTrace;

  @override
  String toString() => 'StorageException($operation): $cause';
}
