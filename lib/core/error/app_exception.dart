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

/// Why an AI enrichment request failed.
enum EnrichmentError {
  /// No API key is saved; no request was sent.
  notConfigured,

  /// The key was rejected (HTTP 401).
  invalidKey,

  /// The OpenRouter account or key has no credits left (HTTP 402).
  insufficientCredits,

  /// Blocked by permissions, a guardrail or moderation (HTTP 403).
  forbidden,

  /// Too many requests (HTTP 429), still failing after retries.
  rateLimited,

  /// The request took too long (client timeout or HTTP 408).
  timeout,

  /// No connection, DNS or TLS failure.
  network,

  /// The selected model is unavailable or no provider can serve it
  /// (HTTP 502/503, unknown model).
  modelUnavailable,

  /// The request was rejected as invalid (HTTP 400).
  badRequest,

  /// Other server-side failures (HTTP 5xx).
  server,

  /// The response was not the structured result that was asked for.
  malformedResponse,

  /// The user cancelled.
  cancelled,
}

/// A failed AI request.
///
/// Never contains the API key, request or response bodies, or vocabulary
/// content: only the reason and the HTTP status, so it is safe to log.
final class EnrichmentException extends AppException {
  const EnrichmentException(this.error, {this.statusCode});

  final EnrichmentError error;

  /// HTTP status, when the server answered.
  final int? statusCode;

  /// Whether retrying later could succeed without the user changing
  /// anything (key, credits, model).
  bool get isTemporary => switch (error) {
    EnrichmentError.rateLimited ||
    EnrichmentError.timeout ||
    EnrichmentError.network ||
    EnrichmentError.server ||
    EnrichmentError.modelUnavailable => true,
    _ => false,
  };

  @override
  String toString() => 'EnrichmentException($error, status: $statusCode)';
}

/// Entries changed after an enrichment proposal was made, so it was not
/// saved (nothing was written).
final class EnrichmentConflictException extends AppException {
  const EnrichmentConflictException(this.entryIds);

  final Set<String> entryIds;

  @override
  String toString() => 'EnrichmentConflictException(${entryIds.length})';
}
