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

  /// Another enrichment run is already requesting this word; nothing was
  /// sent for it in this run.
  busy,

  /// The account's free-model requests for the current day are used up
  /// (OpenRouter resets them daily). Requests are paused until [retryAt].
  dailyQuotaExhausted,

  /// Free-only mode: a request would (or did) use something that is not
  /// verifiably free, so nothing more is sent.
  paidModelBlocked,
}

/// Why an answer was unusable (with [EnrichmentError.malformedResponse]).
enum ResponseProblem {
  /// The model used its whole output budget before writing any answer
  /// (typically on reasoning): `finish_reason: length`, no content.
  cutOffWhileReasoning,

  /// The answer was cut off at the output limit.
  cutOff,

  /// The model returned no text.
  empty,

  /// The text contains no JSON object.
  notJson,

  /// JSON, but not the requested structure.
  unexpectedShape,

  /// The structure was right, but no item passed the checks (e.g. the
  /// target word was missing from every sentence).
  noUsableItems,

  /// The answer contradicted itself (e.g. "correct" with the target word
  /// missing).
  contradictory,
}

/// What happened to one attempt of a request, for diagnostics. Contains
/// model ids, statuses and counts only: never the key, prompts, answers or
/// vocabulary.
class AiAttempt {
  const AiAttempt({
    required this.model,
    required this.outputMode,
    this.answeredBy,
    this.statusCode,
    this.error,
    this.problem,
    this.finishReason,
    this.completionTokens,
    this.reasoningTokens,
    this.contentLength,
    this.detail,
  });

  /// The model requested (e.g. `openrouter/free`).
  final String model;

  /// How JSON was requested (`jsonSchema`, `jsonObject`, `promptOnly`).
  final String outputMode;

  /// The model that actually answered, when known.
  final String? answeredBy;
  final int? statusCode;

  /// Null when the attempt succeeded.
  final EnrichmentError? error;
  final ResponseProblem? problem;
  final String? finishReason;
  final int? completionTokens;
  final int? reasoningTokens;
  final int? contentLength;

  /// Content-free notes, e.g. why generated items were rejected.
  final String? detail;

  @override
  String toString() => [
    '$model${answeredBy != null && answeredBy != model ? ' → $answeredBy' : ''}',
    outputMode,
    if (statusCode != null) 'HTTP $statusCode',
    error == null ? 'ok' : error!.name,
    ?problem?.name,
    if (finishReason != null) 'finish=$finishReason',
    if (completionTokens != null)
      'tokens=$completionTokens'
          '${reasoningTokens != null ? ' (reasoning $reasoningTokens)' : ''}',
    if (contentLength != null) 'chars=$contentLength',
    ?detail,
  ].join(' · ');
}

/// A failed AI request.
///
/// Never contains the API key, request or response bodies, or vocabulary
/// content: only the reason, the HTTP status and content-free diagnostics,
/// so it is safe to log.
final class EnrichmentException extends AppException {
  const EnrichmentException(
    this.error, {
    this.statusCode,
    this.retryAt,
    this.upstream = false,
    this.problem,
    this.detail,
    this.attempts = const [],
  });

  final EnrichmentError error;

  /// HTTP status, when the server answered.
  final int? statusCode;

  /// UTC time before which the same request must not be sent again, when
  /// OpenRouter said so (`Retry-After`, rate-limit reset).
  final DateTime? retryAt;

  /// The failure came from the model provider behind OpenRouter (e.g. a
  /// provider's own rate limit), not from the user's OpenRouter account. A
  /// different free model may succeed.
  final bool upstream;

  /// Why the answer was unusable, for [EnrichmentError.malformedResponse].
  final ResponseProblem? problem;

  /// Content-free diagnostic note (e.g. rejection reasons and counts).
  final String? detail;

  /// Every attempt of the request (set by `OpenRouterChat`).
  final List<AiAttempt> attempts;

  /// This failure with the attempts that led to it.
  EnrichmentException withAttempts(List<AiAttempt> attempts) =>
      EnrichmentException(
        error,
        statusCode: statusCode,
        retryAt: retryAt,
        upstream: upstream,
        problem: problem,
        detail: detail,
        attempts: List.unmodifiable(attempts),
      );

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
  String toString() =>
      'EnrichmentException($error, status: $statusCode'
      '${upstream ? ', upstream' : ''}'
      '${problem != null ? ', ${problem!.name}' : ''})';
}

/// Entries changed after an enrichment proposal was made, so it was not
/// saved (nothing was written).
final class EnrichmentConflictException extends AppException {
  const EnrichmentConflictException(this.entryIds);

  final Set<String> entryIds;

  @override
  String toString() => 'EnrichmentConflictException(${entryIds.length})';
}

/// Reasons a tag name is rejected.
enum TagValidationError { nameEmpty, nameTooLong, nameDuplicate }

final class TagValidationException extends AppException {
  const TagValidationException(this.error);

  final TagValidationError error;

  @override
  String toString() => 'TagValidationException($error)';
}

/// Why text-to-speech could not play.
enum SpeechError {
  /// No voice for the language is installed on the device.
  voiceUnavailable,

  /// The speech engine is missing or failed.
  failed,
}

final class SpeechException extends AppException {
  const SpeechException(this.error);

  final SpeechError error;

  @override
  String toString() => 'SpeechException($error)';
}

/// Why the study reminder could not be changed.
enum ReminderError {
  /// The user did not allow notifications.
  permissionDenied,

  /// The system refused to schedule or cancel the notification, or the
  /// device time zone could not be determined.
  schedulingFailed,
}

final class ReminderException extends AppException {
  const ReminderException(this.error);

  final ReminderError error;

  @override
  String toString() => 'ReminderException($error)';
}

/// Why a file could not be exported.
enum ExportError {
  /// There is nothing to export.
  empty,

  /// The file could not be written to the chosen place.
  writeFailed,
}

final class ExportException extends AppException {
  const ExportException(this.error);

  final ExportError error;

  @override
  String toString() => 'ExportException($error)';
}

/// Why an Anki package could not be read.
enum AnkiImportError {
  /// Not a ZIP-based `.apkg` / `.colpkg`, or the archive is damaged.
  notAnkiPackage,

  /// The package uses a collection format this app cannot read.
  unsupportedFormat,

  /// The package contains no notes.
  noNotes,

  /// The package is larger than the import limit.
  tooLarge,
}

final class AnkiImportException extends AppException {
  const AnkiImportException(this.error);

  final AnkiImportError error;

  @override
  String toString() => 'AnkiImportException($error)';
}

/// Why a backup could not be created, read or restored.
enum BackupError {
  /// Not an AI WortBox backup file (not JSON, or another kind of file).
  notBackup,

  /// Written by a newer backup format than this app version understands.
  unsupportedVersion,

  /// Written by an app with a newer database schema.
  newerSchema,

  /// The content does not match its checksum (changed or damaged).
  corrupted,

  /// A required field is missing.
  missingField,

  /// A field has an invalid value (type, range, enum, date).
  invalidValue,

  /// The same id (or unique value) appears twice in the file.
  duplicateId,

  /// A record refers to a deck, word or tag that is not in the file.
  brokenReference,

  /// The file is larger than the backup limit.
  tooLarge,

  /// The current data could not be saved as a safety copy, so nothing was
  /// restored.
  safetyCopyFailed,
}

final class BackupException extends AppException {
  const BackupException(this.error, {this.location});

  final BackupError error;

  /// Where in the file the problem is, e.g. `entries[3].deckId`. Contains
  /// field names and positions only, never vocabulary content.
  final String? location;

  @override
  String toString() => 'BackupException($error, $location)';
}
