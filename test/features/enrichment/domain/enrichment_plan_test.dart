import 'package:ai_wortbox/core/config/app_config.dart';
import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/core/text/text_normalizer.dart';
import 'package:ai_wortbox/features/enrichment/domain/enrichment.dart';
import 'package:ai_wortbox/features/enrichment/domain/enrichment_plan.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final at = DateTime.utc(2026, 10, 15, 8);

  VocabularyEntry entry(
    String id,
    String original, {
    List<String> meanings = const [],
    String? lemma,
    String? partOfSpeech,
    String? grammarInfo,
    String? example,
    String? exampleTranslation,
    String? context,
    EnrichmentStatus? status,
    DateTime? userEditedAt,
  }) => VocabularyEntry(
    id: id,
    deckId: 'deck',
    original: original,
    normalized: TextNormalizer.vocabularyKey(original),
    sourceLanguage: Language.german,
    definitionLanguage: Language.persian,
    sourceType: VocabularySourceType.image,
    enrichmentStatus:
        status ??
        (meanings.isEmpty ? EnrichmentStatus.missing : EnrichmentStatus.ready),
    createdAt: at,
    updatedAt: at,
    meanings: [for (final m in meanings) VocabularyMeaning(m)],
    lemma: lemma,
    partOfSpeech: partOfSpeech,
    grammarInfo: grammarInfo,
    exampleSentence: example,
    exampleTranslation: exampleTranslation,
    sourceContext: context,
    userEditedAt: userEditedAt,
  );

  EnrichmentProposal proposal({
    List<String> meanings = const ['رفتن'],
    String? lemma = 'gehen',
    String? partOfSpeech = 'Verb',
    String? grammarInfo = 'ging, ist gegangen',
    String? example = 'Wir gehen ins Kino.',
    String? translation = 'ما به سینما می‌رویم.',
  }) => EnrichmentProposal(
    meanings: [for (final m in meanings) ProposedMeaning(m)],
    lemma: lemma,
    partOfSpeech: partOfSpeech,
    grammarInfo: grammarInfo,
    exampleSentence: example,
    exampleTranslation: translation,
    provider: 'openrouter',
    model: 'anthropic/claude-haiku-5.5',
    generatedAt: at,
  );

  group('entries without meanings', () {
    test('all suggestions are offered and preselected', () {
      final plan = EnrichmentPlan.build(entry('e1', 'ging'), proposal());
      expect(plan.newMeanings.map((m) => m.text), ['رفتن']);
      expect(plan.defaultMeanings, {0});
      expect(plan.fields.map((f) => f.field), [
        EnrichmentField.lemma,
        EnrichmentField.partOfSpeech,
        EnrichmentField.grammarInfo,
        EnrichmentField.example,
      ]);
      expect(plan.defaultFields, plan.fields.map((f) => f.field).toSet());
    });

    test('toUpdate contains exactly the chosen parts', () {
      final plan = EnrichmentPlan.build(entry('e1', 'ging'), proposal());
      final update = plan.toUpdate(
        meanings: {0},
        fields: {EnrichmentField.example},
      )!;
      expect(update.entryId, 'e1');
      expect(update.expectedUpdatedAt, at);
      expect(update.addMeanings.single.text, 'رفتن');
      expect(update.exampleSentence, 'Wir gehen ins Kino.');
      expect(update.exampleTranslation, 'ما به سینما می‌رویم.');
      expect(update.lemma, isNull);
      expect(update.partOfSpeech, isNull);
      expect(update.metadata.model, 'anthropic/claude-haiku-5.5');
      expect(update.metadata.provider, 'openrouter');
    });

    test('nothing chosen means no update', () {
      final plan = EnrichmentPlan.build(entry('e1', 'ging'), proposal());
      expect(plan.toUpdate(meanings: {}, fields: {}), isNull);
    });
  });

  group('existing content is protected', () {
    test('existing meanings are kept; only new ones are offered, '
        'not preselected', () {
      final existing = entry('e1', 'Bank', meanings: ['بانک']);
      final plan = EnrichmentPlan.build(
        existing,
        proposal(meanings: ['بانک', 'نیمکت'], lemma: null),
      );
      expect(plan.newMeanings.map((m) => m.text), ['نیمکت']);
      expect(plan.defaultMeanings, isEmpty);
      final update = plan.toUpdate(meanings: {0}, fields: {})!;
      // Only an addition; the update cannot express removal or rewording.
      expect(update.addMeanings.map((m) => m.text), ['نیمکت']);
    });

    test('meanings that differ only in Persian letter variants or marks '
        'are not offered again', () {
      final existing = entry('e1', 'Bank', meanings: ['بانك']); // Arabic kaf
      final plan = EnrichmentPlan.build(
        existing,
        proposal(meanings: ['بانک'], lemma: null),
      );
      expect(plan.newMeanings, isEmpty);
    });

    test(
      'filled fields are offered only as replacements, never preselected',
      () {
        final edited = entry(
          'e1',
          'ging',
          meanings: ['رفت'],
          partOfSpeech: 'Verb',
          grammarInfo: 'Präteritum von gehen',
          example: 'Sie ging nach Hause.',
          exampleTranslation: 'او به خانه رفت.',
          userEditedAt: at,
        );
        final plan = EnrichmentPlan.build(edited, proposal());
        final byField = {for (final f in plan.fields) f.field: f};
        // Same POS: nothing to offer.
        expect(byField.containsKey(EnrichmentField.partOfSpeech), isFalse);
        expect(byField[EnrichmentField.grammarInfo]!.fillsEmpty, isFalse);
        expect(
          byField[EnrichmentField.grammarInfo]!.current,
          'Präteritum von gehen',
        );
        expect(byField[EnrichmentField.example]!.fillsEmpty, isFalse);
        // The empty lemma is still filled by default; replacements are not.
        expect(plan.defaultFields, {EnrichmentField.lemma});
      },
    );

    test('a translation without its sentence still counts as content', () {
      final partial = entry('e1', 'ging', exampleTranslation: 'او رفت.');
      final plan = EnrichmentPlan.build(partial, proposal());
      final example = plan.fields.singleWhere(
        (f) => f.field == EnrichmentField.example,
      );
      expect(example.fillsEmpty, isFalse);
      expect(plan.defaultFields.contains(EnrichmentField.example), isFalse);
    });

    test('never exceeds the per-entry meaning limit', () {
      final full = entry(
        'e1',
        'Bank',
        meanings: [
          for (var i = 0; i < AppConfig.maxMeaningsPerEntry; i++) 'معنی $i',
        ],
      );
      final plan = EnrichmentPlan.build(
        full,
        proposal(meanings: ['نیمکت'], lemma: null),
      );
      expect(plan.newMeanings, isEmpty);
    });
  });

  group('batch candidates', () {
    test('only entries without meanings that are missing or failed', () {
      final entries = [
        entry('a', 'a'),
        entry('b', 'b', meanings: ['ب']),
        entry('c', 'c', status: EnrichmentStatus.failed),
        entry('d', 'd', status: EnrichmentStatus.pending),
        entry('e', 'e', status: EnrichmentStatus.ready),
      ];
      expect(batchCandidates(entries).map((e) => e.id), ['a', 'c']);
    });

    test('is limited to the batch size', () {
      final many = [
        for (var i = 0; i < AppConfig.aiMaxBatchSize + 10; i++)
          entry('$i', 'w$i'),
      ];
      expect(batchCandidates(many), hasLength(AppConfig.aiMaxBatchSize));
    });
  });

  test('the request contains only the word, context and meanings', () {
    final request = requestFor(
      entry(
        'e1',
        'Mühe',
        meanings: ['زحمت'],
        context: 'Am Morgen ging sie mit großer Mühe in die Stadt.',
        grammarInfo: 'private note',
      ),
    );
    expect(request.original, 'Mühe');
    expect(
      request.sourceContext,
      'Am Morgen ging sie mit großer Mühe in die Stadt.',
    );
    expect(request.existingMeanings, ['زحمت']);
  });
}
