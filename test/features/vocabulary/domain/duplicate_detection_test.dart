import 'package:ai_wortbox/features/vocabulary/domain/duplicate_detection.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/entries.dart';

ImportCandidate row(int n, String word, List<String> meanings) =>
    ImportCandidate(rowNumber: n, draft: testDraft(word, meanings));

String describe(ImportDecision d) => switch (d) {
  CreateDecision() => 'create',
  MergeIntoEntryDecision(:final entryId) => 'merge:$entryId',
  MergeIntoRowDecision(:final targetRowNumber) => 'mergeRow:$targetRowNumber',
  SkipDecision(:final reason, :final entryId, :final targetRowNumber) =>
    'skip:${reason.name}:${entryId ?? 'row$targetRowNumber'}',
};

void main() {
  group('checkDuplicate', () {
    final existing = [
      testEntry('e2', 'Bank', ['نیمکت'], minute: 2),
      testEntry('e1', 'Bank', ['بانک'], minute: 1),
      testEntry('e3', 'Haus', ['خانه']),
      testEntry('other', 'Bank', ['بانک'], deckId: 'other-deck'),
    ];

    test('no match in the same deck', () {
      expect(
        checkDuplicate(testDraft('Baum', []), existing),
        isA<NoDuplicate>(),
      );
      expect(
        checkDuplicate(testDraft('Bank', [], deckId: 'third'), existing),
        isA<NoDuplicate>(),
      );
    });

    test(
      'redundant when meanings are a subset (case and punctuation ignored)',
      () {
        final check = checkDuplicate(testDraft('„bank“', ['بانک']), existing);
        expect(check, isA<RedundantDuplicate>());
        expect((check as RedundantDuplicate).existing.id, 'e1');
      },
    );

    test('a draft without meanings is redundant to any existing word', () {
      expect(
        checkDuplicate(testDraft('Haus', []), existing),
        isA<RedundantDuplicate>(),
      );
    });

    test('different meanings are reported, never merged, oldest first', () {
      final check = checkDuplicate(testDraft('Bank', ['ساحل']), existing);
      expect(check, isA<SameWordDifferentMeanings>());
      expect((check as SameWordDifferentMeanings).existing.map((e) => e.id), [
        'e1',
        'e2',
      ]);
    });

    test('ignores the entry being edited', () {
      expect(
        checkDuplicate(
          testDraft('Haus', ['خانه']),
          existing,
          excludeEntryId: 'e3',
        ),
        isA<NoDuplicate>(),
      );
    });
  });

  group('planImport', () {
    final existing = [
      testEntry('haus', 'Haus', ['خانه']),
    ];
    final rows = [
      row(1, 'Bank', ['بانک']),
      row(2, 'Bank', ['نیمکت']),
      row(3, 'bank', ['بانک']),
      row(4, 'Haus', ['خانه']),
      row(5, 'Haus', ['منزل']),
      row(6, 'Baum', []),
    ];

    test('skip strategy', () {
      expect(planImport(rows, existing, DuplicateStrategy.skip).map(describe), [
        'create',
        'skip:wordExists:row1',
        'skip:redundant:row1',
        'skip:redundant:haus',
        'skip:wordExists:haus',
        'create',
      ]);
    });

    test('merge strategy merges into existing entries and earlier rows', () {
      expect(
        planImport(
          rows,
          existing,
          DuplicateStrategy.mergeMeanings,
        ).map(describe),
        [
          'create',
          'mergeRow:1',
          'skip:redundant:row1',
          'skip:redundant:haus',
          'merge:haus',
          'create',
        ],
      );
    });

    test('merged meanings count for later redundancy checks', () {
      final decisions = planImport(
        [
          row(1, 'Haus', ['منزل']),
          row(2, 'Haus', ['منزل']),
        ],
        existing,
        DuplicateStrategy.mergeMeanings,
      );
      expect(decisions.map(describe), ['merge:haus', 'skip:redundant:haus']);
    });

    test('keepSeparate creates entries for different meanings only', () {
      expect(
        planImport(
          rows,
          existing,
          DuplicateStrategy.keepSeparate,
        ).map(describe),
        [
          'create',
          'create',
          'skip:redundant:row1',
          'skip:redundant:haus',
          'create',
          'create',
        ],
      );
    });

    test('is deterministic', () {
      for (final strategy in DuplicateStrategy.values) {
        expect(
          planImport(rows, existing, strategy).map(describe).toList(),
          planImport(rows, existing, strategy).map(describe).toList(),
        );
      }
    });
  });

  group('mergeDrafts', () {
    test('appends new meanings and fills only empty fields', () {
      const base = VocabularyDraft(
        deckId: 'd',
        original: 'Bank',
        meanings: [VocabularyMeaning('بانک')],
        exampleSentence: 'Ich gehe zur Bank.',
      );
      const extra = VocabularyDraft(
        deckId: 'd',
        original: 'bank',
        meanings: [VocabularyMeaning('بانک'), VocabularyMeaning('نیمکت')],
        exampleSentence: 'Er sitzt auf der Bank.',
        notes: 'zwei Bedeutungen',
      );
      final merged = mergeDrafts(base, extra);
      expect(merged.original, 'Bank');
      expect(merged.meanings.map((m) => m.text), ['بانک', 'نیمکت']);
      expect(merged.exampleSentence, 'Ich gehe zur Bank.');
      expect(merged.notes, 'zwei Bedeutungen');
    });
  });
}
