import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/text/text_normalizer.dart';
import 'vocabulary_entry.dart';

/// User-editable vocabulary content, used to create or update an entry.
///
/// Languages, ids, timestamps and enrichment state are not part of a draft;
/// they are owned by the repository and the deck.
@immutable
class VocabularyDraft {
  const VocabularyDraft({
    required this.deckId,
    required this.original,
    this.meanings = const [],
    this.lemma,
    this.partOfSpeech,
    this.exampleSentence,
    this.exampleTranslation,
    this.grammarInfo,
    this.notes,
    this.sourceContext,
    this.sourceType = VocabularySourceType.manual,
  });

  /// A draft pre-filled from an existing entry, for editing.
  factory VocabularyDraft.fromEntry(VocabularyEntry entry) => VocabularyDraft(
    deckId: entry.deckId,
    original: entry.original,
    meanings: entry.meanings,
    lemma: entry.lemma,
    partOfSpeech: entry.partOfSpeech,
    exampleSentence: entry.exampleSentence,
    exampleTranslation: entry.exampleTranslation,
    grammarInfo: entry.grammarInfo,
    notes: entry.notes,
    sourceContext: entry.sourceContext,
    sourceType: entry.sourceType,
  );

  final String deckId;
  final String original;
  final List<VocabularyMeaning> meanings;
  final String? lemma;
  final String? partOfSpeech;
  final String? exampleSentence;
  final String? exampleTranslation;
  final String? grammarInfo;
  final String? notes;
  final String? sourceContext;
  final VocabularySourceType sourceType;

  /// Comparison key of [original] used for duplicate detection.
  String get normalized => TextNormalizer.vocabularyKey(original);

  /// A copy with whitespace cleaned up, blank optional fields set to null, and
  /// blank or repeated meanings removed (first occurrence wins). The spelling
  /// of [original] is otherwise preserved exactly.
  VocabularyDraft cleaned() {
    final seen = <String>{};
    final cleanedMeanings = <VocabularyMeaning>[];
    for (final meaning in meanings) {
      final text = TextNormalizer.collapseWhitespace(meaning.text);
      if (text.isEmpty || !seen.add(TextNormalizer.meaningKey(text))) continue;
      cleanedMeanings.add(
        VocabularyMeaning(text, explanation: _optional(meaning.explanation)),
      );
    }
    return VocabularyDraft(
      deckId: deckId,
      original: TextNormalizer.collapseWhitespace(original),
      meanings: List.unmodifiable(cleanedMeanings),
      lemma: _optional(lemma),
      partOfSpeech: _optional(partOfSpeech),
      exampleSentence: _optional(exampleSentence),
      exampleTranslation: _optional(exampleTranslation),
      grammarInfo: _optional(grammarInfo),
      notes: _optionalMultiline(notes),
      sourceContext: _optional(sourceContext),
      sourceType: sourceType,
    );
  }

  /// Validates a [cleaned] draft. Meanings are optional: entries without
  /// meanings are kept with [EnrichmentStatus.missing] for later enrichment.
  Set<VocabularyValidationError> validate() {
    final errors = <VocabularyValidationError>{};
    if (original.trim().isEmpty) {
      errors.add(VocabularyValidationError.originalEmpty);
    } else if (original.runes.length > AppConfig.maxOriginalLength) {
      errors.add(VocabularyValidationError.originalTooLong);
    }
    if (meanings.length > AppConfig.maxMeaningsPerEntry) {
      errors.add(VocabularyValidationError.tooManyMeanings);
    }
    if (meanings.any(
      (m) =>
          m.text.runes.length > AppConfig.maxMeaningLength ||
          (m.explanation?.runes.length ?? 0) > AppConfig.maxTextFieldLength,
    )) {
      errors.add(VocabularyValidationError.meaningTooLong);
    }
    final optionalFields = [
      lemma,
      partOfSpeech,
      exampleSentence,
      exampleTranslation,
      grammarInfo,
      notes,
      sourceContext,
    ];
    if (optionalFields.any(
      (f) => (f?.runes.length ?? 0) > AppConfig.maxTextFieldLength,
    )) {
      errors.add(VocabularyValidationError.fieldTooLong);
    }
    return errors;
  }

  /// Normalized keys of all meanings, for duplicate comparison.
  Set<String> get meaningKeys => {
    for (final m in meanings) TextNormalizer.meaningKey(m.text),
  };

  VocabularyDraft copyWith({
    String? deckId,
    String? original,
    List<VocabularyMeaning>? meanings,
  }) => VocabularyDraft(
    deckId: deckId ?? this.deckId,
    original: original ?? this.original,
    meanings: meanings ?? this.meanings,
    lemma: lemma,
    partOfSpeech: partOfSpeech,
    exampleSentence: exampleSentence,
    exampleTranslation: exampleTranslation,
    grammarInfo: grammarInfo,
    notes: notes,
    sourceContext: sourceContext,
    sourceType: sourceType,
  );

  @override
  bool operator ==(Object other) =>
      other is VocabularyDraft &&
      other.deckId == deckId &&
      other.original == original &&
      listEquals(other.meanings, meanings) &&
      other.lemma == lemma &&
      other.partOfSpeech == partOfSpeech &&
      other.exampleSentence == exampleSentence &&
      other.exampleTranslation == exampleTranslation &&
      other.grammarInfo == grammarInfo &&
      other.notes == notes &&
      other.sourceContext == sourceContext &&
      other.sourceType == sourceType;

  @override
  int get hashCode => Object.hash(
    deckId,
    original,
    Object.hashAll(meanings),
    lemma,
    partOfSpeech,
    exampleSentence,
    exampleTranslation,
    grammarInfo,
    notes,
    sourceContext,
    sourceType,
  );

  static String? _optional(String? value) {
    if (value == null) return null;
    final cleaned = TextNormalizer.collapseWhitespace(value);
    return cleaned.isEmpty ? null : cleaned;
  }

  // Notes may intentionally contain line breaks; only trim the edges.
  static String? _optionalMultiline(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

extension VocabularyEntryMeaningKeys on VocabularyEntry {
  Set<String> get meaningKeys => {
    for (final m in meanings) TextNormalizer.meaningKey(m.text),
  };
}
