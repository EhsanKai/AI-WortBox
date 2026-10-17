import 'package:flutter/foundation.dart';

import 'duplicate_detection.dart';
import 'enrichment_update.dart';
import 'vocabulary_draft.dart';
import 'vocabulary_entry.dart';

/// Persistence boundary for vocabulary entries.
///
/// Implementations throw [VocabularyValidationException] for invalid input,
/// [NotFoundException] for unknown ids and [StorageException] for database
/// failures. No method ever modifies review state (flashcards).
abstract interface class VocabularyRepository {
  /// Entries of a deck with their meanings, newest first.
  Stream<List<VocabularyEntry>> watchEntries(String deckId);

  Stream<VocabularyEntry?> watchEntry(String id);

  Future<List<VocabularyEntry>> getEntries(String deckId);

  Future<VocabularyEntry?> getEntry(String id);

  /// Entries in [deckId] whose normalized form equals [normalized]. Several
  /// entries with distinct meanings may match.
  Future<List<VocabularyEntry>> findByNormalized(
    String deckId,
    String normalized,
  );

  /// Creates an entry from user input (marks it as user-edited).
  Future<VocabularyEntry> createEntry(VocabularyDraft draft);

  /// Replaces the content of entry [id] with [draft] (marks it as
  /// user-edited). Review state is preserved.
  Future<VocabularyEntry> updateEntry(String id, VocabularyDraft draft);

  /// Adds [draft]'s new meanings to entry [id] and fills its empty optional
  /// fields, without overwriting anything (see `mergeDrafts`).
  Future<VocabularyEntry> mergeIntoEntry(String id, VocabularyDraft draft);

  /// Applies reviewed AI content in a single transaction: meanings are only
  /// added (never removed or reordered), the given fields are set, the
  /// status becomes `ready` when the entry has meanings, and the metadata is
  /// stored. `userEditedAt` and review state are never changed.
  ///
  /// Throws [EnrichmentConflictException] (writing nothing) when any entry
  /// changed since its proposal was made, and [NotFoundException] when one
  /// was deleted.
  Future<List<VocabularyEntry>> applyEnrichments(
    List<EnrichmentUpdate> updates,
  );

  /// Deletes the entry, its meanings and its flashcards.
  Future<void> deleteEntry(String id);

  /// Imports [candidates] into [deckId] in a single transaction, using
  /// `planImport` against the deck's current entries. Either every write
  /// succeeds or none is kept.
  Future<ImportSummary> importEntries(
    String deckId,
    List<ImportCandidate> candidates,
    DuplicateStrategy strategy,
  );
}

@immutable
class ImportSummary {
  const ImportSummary({required this.decisions});

  final List<ImportDecision> decisions;

  int get createdCount => decisions.whereType<CreateDecision>().length;

  /// Rows whose meanings were added to an existing entry or to an entry
  /// created earlier in the same import.
  int get mergedCount => decisions
      .where((d) => d is MergeIntoEntryDecision || d is MergeIntoRowDecision)
      .length;

  int get skippedCount => decisions.whereType<SkipDecision>().length;
}
