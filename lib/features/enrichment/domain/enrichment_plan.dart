import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/text/text_normalizer.dart';
import '../../vocabulary/domain/enrichment_update.dart';
import '../../vocabulary/domain/vocabulary_entry.dart';
import 'enrichment.dart';

/// Fields an AI proposal can fill. The example sentence and its translation
/// always go together.
enum EnrichmentField { lemma, partOfSpeech, grammarInfo, example }

/// A proposed value next to the entry's current value.
@immutable
class FieldSuggestion {
  const FieldSuggestion({
    required this.field,
    required this.proposed,
    this.current,
    this.proposedTranslation,
    this.currentTranslation,
  });

  final EnrichmentField field;
  final String proposed;
  final String? current;

  /// For [EnrichmentField.example] only.
  final String? proposedTranslation;
  final String? currentTranslation;

  /// The entry has nothing here yet; filling it overwrites nothing.
  bool get fillsEmpty =>
      current == null &&
      (field != EnrichmentField.example || currentTranslation == null);
}

/// What a proposal would change on one entry, and what needs a decision.
///
/// Rules:
/// - existing meanings are never removed or changed; only meanings that are
///   not already present are offered, and only up to the entry limit;
/// - empty fields are offered for filling (selected by default);
/// - fields with content are offered as *replacements*, never selected by
///   default;
/// - new meanings are selected by default only when the entry has none.
@immutable
class EnrichmentPlan {
  const EnrichmentPlan._({
    required this.entry,
    required this.proposal,
    required this.newMeanings,
    required this.fields,
  });

  factory EnrichmentPlan.build(
    VocabularyEntry entry,
    EnrichmentProposal proposal,
  ) {
    final known = {
      for (final m in entry.meanings) TextNormalizer.meaningKey(m.text),
    };
    final room = AppConfig.maxMeaningsPerEntry - entry.meanings.length;
    final newMeanings = [
      for (final m in proposal.meanings)
        if (known.add(TextNormalizer.meaningKey(m.text)))
          VocabularyMeaning(m.text, explanation: m.explanation),
    ].take(room < 0 ? 0 : room).toList();

    String key(String s) => TextNormalizer.vocabularyKey(s);
    bool differs(String? current, String proposed) =>
        current == null || key(current) != key(proposed);

    final fields = <FieldSuggestion>[
      if (proposal.lemma case final lemma? when differs(entry.lemma, lemma))
        FieldSuggestion(
          field: EnrichmentField.lemma,
          proposed: lemma,
          current: entry.lemma,
        ),
      if (proposal.partOfSpeech case final pos?
          when differs(entry.partOfSpeech, pos))
        FieldSuggestion(
          field: EnrichmentField.partOfSpeech,
          proposed: pos,
          current: entry.partOfSpeech,
        ),
      if (proposal.grammarInfo case final grammar?
          when differs(entry.grammarInfo, grammar))
        FieldSuggestion(
          field: EnrichmentField.grammarInfo,
          proposed: grammar,
          current: entry.grammarInfo,
        ),
      if ((proposal.exampleSentence, proposal.exampleTranslation)
          case (final sentence?, final translation?)
          when differs(entry.exampleSentence, sentence))
        FieldSuggestion(
          field: EnrichmentField.example,
          proposed: sentence,
          proposedTranslation: translation,
          current: entry.exampleSentence,
          currentTranslation: entry.exampleTranslation,
        ),
    ];

    return EnrichmentPlan._(
      entry: entry,
      proposal: proposal,
      newMeanings: List.unmodifiable(newMeanings),
      fields: List.unmodifiable(fields),
    );
  }

  final VocabularyEntry entry;
  final EnrichmentProposal proposal;
  final List<VocabularyMeaning> newMeanings;
  final List<FieldSuggestion> fields;

  bool get hasSuggestions => newMeanings.isNotEmpty || fields.isNotEmpty;

  /// Indices of [newMeanings] selected before the user decides.
  Set<int> get defaultMeanings => entry.hasMeanings
      ? const {}
      : {for (var i = 0; i < newMeanings.length; i++) i};

  /// Fields selected before the user decides: only empty ones.
  Set<EnrichmentField> get defaultFields => {
    for (final f in fields)
      if (f.fillsEmpty) f.field,
  };

  /// The write for the user's choices, or null when nothing was chosen.
  EnrichmentUpdate? toUpdate({
    required Set<int> meanings,
    required Set<EnrichmentField> fields,
  }) {
    String? chosen(EnrichmentField field) =>
        fields.contains(field) ? _field(field)?.proposed : null;
    final example = fields.contains(EnrichmentField.example)
        ? _field(EnrichmentField.example)
        : null;
    final update = EnrichmentUpdate(
      entryId: entry.id,
      expectedUpdatedAt: entry.updatedAt,
      addMeanings: [
        for (final (i, m) in newMeanings.indexed)
          if (meanings.contains(i)) m,
      ],
      lemma: chosen(EnrichmentField.lemma),
      partOfSpeech: chosen(EnrichmentField.partOfSpeech),
      grammarInfo: chosen(EnrichmentField.grammarInfo),
      exampleSentence: example?.proposed,
      exampleTranslation: example?.proposedTranslation,
      metadata: EnrichmentMetadata(
        provider: proposal.provider,
        model: proposal.model,
        generatedAt: proposal.generatedAt,
        isAmbiguous: proposal.isAmbiguous,
      ),
    );
    return update.changesContent ? update : null;
  }

  FieldSuggestion? _field(EnrichmentField field) =>
      fields.where((f) => f.field == field).firstOrNull;
}

/// Entries of a deck that may be enriched in a batch: no meanings yet, and
/// not already enriched. Entries with meanings are never enriched
/// automatically.
List<VocabularyEntry> batchCandidates(List<VocabularyEntry> entries) => [
  for (final e in entries)
    if (!e.hasMeanings &&
        (e.enrichmentStatus == EnrichmentStatus.missing ||
            e.enrichmentStatus == EnrichmentStatus.failed))
      e,
].take(AppConfig.aiMaxBatchSize).toList();

/// The request for [entry]: its word, context and current meanings only.
EnrichmentRequest requestFor(VocabularyEntry entry) => EnrichmentRequest(
  original: entry.original,
  sourceContext: entry.sourceContext,
  existingMeanings: [for (final m in entry.meanings) m.text],
  sourceLanguage: entry.sourceLanguage,
  definitionLanguage: entry.definitionLanguage,
);
