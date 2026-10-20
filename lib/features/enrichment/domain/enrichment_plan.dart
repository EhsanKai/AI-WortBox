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
  ///
  /// [edits] replaces the text of suggested meanings (by index into
  /// [newMeanings]) with the user's corrections. Whitespace is collapsed;
  /// a meaning that is blank, or repeats an existing or earlier chosen
  /// meaning, is left out.
  EnrichmentUpdate? toUpdate({
    required Set<int> meanings,
    required Set<EnrichmentField> fields,
    Map<int, String> edits = const {},
  }) {
    final known = {
      for (final m in entry.meanings) TextNormalizer.meaningKey(m.text),
    };
    final chosenMeanings = <VocabularyMeaning>[];
    for (final (i, m) in newMeanings.indexed) {
      if (!meanings.contains(i)) continue;
      final text = TextNormalizer.collapseWhitespace(edits[i] ?? m.text);
      if (text.isEmpty || !known.add(TextNormalizer.meaningKey(text))) {
        continue;
      }
      chosenMeanings.add(
        text == m.text
            ? m
            : VocabularyMeaning(text, explanation: m.explanation),
      );
    }
    String? chosen(EnrichmentField field) =>
        fields.contains(field) ? _field(field)?.proposed : null;
    final example = fields.contains(EnrichmentField.example)
        ? _field(EnrichmentField.example)
        : null;
    final update = EnrichmentUpdate(
      entryId: entry.id,
      expectedUpdatedAt: entry.updatedAt,
      addMeanings: chosenMeanings,
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

/// Selected entries that may be sent for meanings: those without a
/// meaning (see `VocabularyEntry.lacksMeaning`), whatever their enrichment
/// status. Entries with a meaning are never sent from a selection, so
/// their meanings cannot be changed.
List<VocabularyEntry> selectionCandidates(List<VocabularyEntry> selected) => [
  for (final e in selected)
    if (e.lacksMeaning) e,
];

/// The request for [entry]: its word, context and current meanings only.
EnrichmentRequest requestFor(
  VocabularyEntry entry, {
  EnrichmentScope scope = EnrichmentScope.full,
}) => EnrichmentRequest(
  original: entry.original,
  sourceContext: entry.sourceContext,
  existingMeanings: [
    for (final m in entry.meanings)
      if (m.text.trim().isNotEmpty) m.text,
  ],
  sourceLanguage: entry.sourceLanguage,
  definitionLanguage: entry.definitionLanguage,
  scope: scope,
);

/// Characters of [request] that count towards
/// [AppConfig.aiMaxBatchInputChars].
int requestSize(EnrichmentRequest request) =>
    request.original.length +
    (request.sourceContext?.length ?? 0) +
    request.existingMeanings.fold(0, (sum, m) => sum + m.length);

/// The first requests of [sizes] (each request's [requestSize], in queue
/// order) that go into the next batch: at most [maxWords], and no more than
/// [maxChars] together. Always at least one, so an unusually long word is
/// still sent (alone). Returns how many to take.
int nextBatchLength(
  List<int> sizes, {
  required int maxWords,
  int maxChars = AppConfig.aiMaxBatchInputChars,
}) {
  var total = 0;
  var count = 0;
  for (final size in sizes) {
    if (count == maxWords) break;
    if (count > 0 && total + size > maxChars) break;
    total += size;
    count++;
  }
  return count;
}
