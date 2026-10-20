import 'package:flutter/foundation.dart';

import '../../../core/language/language.dart';

/// Where a vocabulary entry came from.
///
/// Persisted by [name]; never rename existing values without a migration.
enum VocabularySourceType { manual, csv, image }

/// Whether AI-generated content exists for an entry.
///
/// Persisted by [name]; never rename existing values without a migration.
enum EnrichmentStatus { missing, pending, ready, failed }

/// One meaning of a vocabulary entry in the definition language.
@immutable
class VocabularyMeaning {
  const VocabularyMeaning(this.text, {this.explanation});

  final String text;

  /// Optional short clarification in the definition language.
  final String? explanation;

  @override
  bool operator ==(Object other) =>
      other is VocabularyMeaning &&
      other.text == text &&
      other.explanation == explanation;

  @override
  int get hashCode => Object.hash(text, explanation);

  @override
  String toString() => 'VocabularyMeaning($text)';
}

/// Information about the AI enrichment that produced an entry's content.
@immutable
class EnrichmentMetadata {
  const EnrichmentMetadata({
    required this.provider,
    required this.model,
    required this.generatedAt,
    this.isAmbiguous = false,
  });

  factory EnrichmentMetadata.fromJson(Map<String, Object?> json) =>
      EnrichmentMetadata(
        provider: json['provider']! as String,
        model: json['model']! as String,
        generatedAt: DateTime.parse(json['generatedAt']! as String).toUtc(),
        isAmbiguous: json['isAmbiguous'] as bool? ?? false,
      );

  final String provider;
  final String model;

  /// UTC.
  final DateTime generatedAt;

  /// The model indicated the meaning may depend on context. This is a hint,
  /// not a calibrated probability.
  final bool isAmbiguous;

  Map<String, Object?> toJson() => {
    'provider': provider,
    'model': model,
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'isAmbiguous': isAmbiguous,
  };

  @override
  bool operator ==(Object other) =>
      other is EnrichmentMetadata &&
      other.provider == provider &&
      other.model == model &&
      other.generatedAt == generatedAt &&
      other.isAmbiguous == isAmbiguous;

  @override
  int get hashCode => Object.hash(provider, model, generatedAt, isAmbiguous);
}

/// A word or multi-word expression the user wants to learn.
///
/// Vocabulary content is stored separately from review scheduling state
/// (see `Flashcard`), so editing an entry never resets review progress.
@immutable
class VocabularyEntry {
  const VocabularyEntry({
    required this.id,
    required this.deckId,
    required this.original,
    required this.normalized,
    required this.sourceLanguage,
    required this.definitionLanguage,
    required this.sourceType,
    required this.enrichmentStatus,
    required this.createdAt,
    required this.updatedAt,
    this.meanings = const [],
    this.lemma,
    this.partOfSpeech,
    this.exampleSentence,
    this.exampleTranslation,
    this.grammarInfo,
    this.notes,
    this.sourceContext,
    this.enrichmentMetadata,
    this.userEditedAt,
    this.markedDifficultAt,
  });

  final String id;
  final String deckId;

  /// Exactly as entered, scanned or imported. Never rewritten.
  final String original;

  /// Comparison key used for duplicate detection.
  final String normalized;

  /// Optional dictionary form (e.g. infinitive), kept alongside [original].
  final String? lemma;

  final Language sourceLanguage;
  final Language definitionLanguage;

  /// Ordered meanings; the first is the primary one.
  final List<VocabularyMeaning> meanings;

  final String? partOfSpeech;

  /// Example sentence in the source language.
  final String? exampleSentence;

  /// Translation of [exampleSentence] in the definition language.
  final String? exampleTranslation;

  /// E.g. gender and plural for nouns, separable prefix for verbs.
  final String? grammarInfo;

  final String? notes;

  /// Surrounding sentence the item was selected from (scan/import).
  final String? sourceContext;

  final VocabularySourceType sourceType;
  final EnrichmentStatus enrichmentStatus;
  final EnrichmentMetadata? enrichmentMetadata;

  /// UTC time the user last edited meanings manually. AI regeneration must
  /// ask before overwriting content when this is set.
  final DateTime? userEditedAt;

  /// UTC.
  final DateTime createdAt;

  /// UTC.
  final DateTime updatedAt;

  /// UTC time the user marked this word as difficult; null when not marked.
  /// Not content: changing it does not change [updatedAt].
  final DateTime? markedDifficultAt;

  bool get isDifficult => markedDifficultAt != null;

  bool get hasMeanings => meanings.isNotEmpty;

  /// No meaning with visible text. Optional fields (example, notes,
  /// grammar) do not count. Same rule as `VocabularyQuery.missingMeaningOnly`.
  bool get lacksMeaning => !meanings.any((m) => m.text.trim().isNotEmpty);

  bool get isMultiWordExpression => original.trim().contains(RegExp(r'\s'));

  @override
  bool operator ==(Object other) =>
      other is VocabularyEntry &&
      other.id == id &&
      other.deckId == deckId &&
      other.original == original &&
      other.normalized == normalized &&
      other.lemma == lemma &&
      other.sourceLanguage == sourceLanguage &&
      other.definitionLanguage == definitionLanguage &&
      listEquals(other.meanings, meanings) &&
      other.partOfSpeech == partOfSpeech &&
      other.exampleSentence == exampleSentence &&
      other.exampleTranslation == exampleTranslation &&
      other.grammarInfo == grammarInfo &&
      other.notes == notes &&
      other.sourceContext == sourceContext &&
      other.sourceType == sourceType &&
      other.enrichmentStatus == enrichmentStatus &&
      other.enrichmentMetadata == enrichmentMetadata &&
      other.userEditedAt == userEditedAt &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.markedDifficultAt == markedDifficultAt;

  @override
  int get hashCode => Object.hashAll([
    id,
    deckId,
    original,
    normalized,
    lemma,
    sourceLanguage,
    definitionLanguage,
    Object.hashAll(meanings),
    partOfSpeech,
    exampleSentence,
    exampleTranslation,
    grammarInfo,
    notes,
    sourceContext,
    sourceType,
    enrichmentStatus,
    enrichmentMetadata,
    userEditedAt,
    createdAt,
    updatedAt,
    markedDifficultAt,
  ]);

  @override
  String toString() => 'VocabularyEntry($id, $original)';
}
