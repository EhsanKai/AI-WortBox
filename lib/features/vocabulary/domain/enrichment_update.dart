import 'package:flutter/foundation.dart';

import 'vocabulary_entry.dart';

/// Reviewed AI content to write to one entry.
///
/// Meanings are only ever *added*. A field is changed only when its value
/// here is non-null; the user decided each one on the review screen.
/// Saving never sets `userEditedAt` and never touches review state.
@immutable
class EnrichmentUpdate {
  const EnrichmentUpdate({
    required this.entryId,
    required this.expectedUpdatedAt,
    required this.metadata,
    this.addMeanings = const [],
    this.lemma,
    this.partOfSpeech,
    this.grammarInfo,
    this.exampleSentence,
    this.exampleTranslation,
  });

  final String entryId;

  /// The entry's `updatedAt` when the proposal was reviewed. If the entry
  /// changed since, nothing is saved (`EnrichmentConflictException`).
  final DateTime expectedUpdatedAt;

  final List<VocabularyMeaning> addMeanings;
  final String? lemma;
  final String? partOfSpeech;
  final String? grammarInfo;
  final String? exampleSentence;
  final String? exampleTranslation;
  final EnrichmentMetadata metadata;

  bool get changesContent =>
      addMeanings.isNotEmpty ||
      lemma != null ||
      partOfSpeech != null ||
      grammarInfo != null ||
      exampleSentence != null ||
      exampleTranslation != null;
}
