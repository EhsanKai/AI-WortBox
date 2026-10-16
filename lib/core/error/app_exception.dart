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

/// Reasons a vocabulary entry cannot be saved.
enum VocabularyValidationError {
  originalEmpty,
  originalTooLong,
  meaningTooLong,
  tooManyMeanings,
  fieldTooLong,
  deckNotFound,
}

final class VocabularyValidationException extends AppException {
  const VocabularyValidationException(this.errors);

  final Set<VocabularyValidationError> errors;

  @override
  String toString() => 'VocabularyValidationException($errors)';
}

/// Fatal problems that make a CSV file unusable as a whole. Row-level
/// problems are reported per row instead and do not throw.
enum CsvFormatError {
  empty,
  tooLarge,
  tooManyRows,
  unsupportedEncoding,
  unterminatedQuote,
  noDataRows,
}

final class CsvFormatException extends AppException {
  const CsvFormatException(this.error, {this.line});

  final CsvFormatError error;

  /// 1-based physical line where the problem starts, when known.
  final int? line;

  @override
  String toString() => 'CsvFormatException($error, line: $line)';
}

/// Problems while obtaining or reading a page image.
enum ScanError {
  cameraPermissionDenied,
  photoPermissionDenied,
  cameraUnavailable,
  unsupportedFormat,
  imageTooLarge,
  unreadableImage,
  ocrUnavailable,
  ocrFailed,
}

final class ScanException extends AppException {
  const ScanException(this.error, [this.cause]);

  final ScanError error;

  /// Underlying platform error, for diagnostics only.
  final Object? cause;

  bool get isPermissionError =>
      error == ScanError.cameraPermissionDenied ||
      error == ScanError.photoPermissionDenied;

  @override
  String toString() => 'ScanException($error)';
}
