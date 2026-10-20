import 'dart:convert';
import 'dart:math';

import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/features/sentence_practice/domain/sentence_exercise.dart';
import 'package:ai_wortbox/features/sentence_practice/domain/sentence_practice.dart';
import 'package:ai_wortbox/features/sentence_practice/domain/sentence_practice_parser.dart';
import 'package:ai_wortbox/features/sentence_practice/domain/target_word_matcher.dart';
import 'package:ai_wortbox/features/sentence_practice/domain/word_selection.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/entries.dart';
import '../../helpers/sentence_fakes.dart';

Matcher throwsMalformed() => throwsA(
  isA<EnrichmentException>().having(
    (e) => e.error,
    'error',
    EnrichmentError.malformedResponse,
  ),
);

void main() {
  group('TargetWordMatcher', () {
    bool m(String sentence, String word, {String? lemma}) =>
        TargetWordMatcher.matches(sentence, word, lemma: lemma);

    test('accepts the word and its grammatical forms', () {
      expect(m('Das Haus ist alt.', 'Haus'), isTrue);
      expect(m('Die Häuser sind alt.', 'Haus'), isTrue);
      expect(m('Wir gehen nach Hause.', 'das Haus'), isTrue);
      expect(m('Er geht nach Hause.', 'gehen'), isTrue);
      expect(m('Gestern ging ich früh.', 'gehen'), isTrue);
      expect(m('Sie ist gegangen.', 'gehen'), isTrue);
      expect(m('Ich habe es gemacht.', 'machen'), isTrue);
      expect(m('Der Film fängt um acht an.', 'anfangen'), isTrue);
      expect(m('Sie war müde.', 'sein'), isTrue);
      expect(m('Er freut sich auf die Ferien.', 'sich freuen'), isTrue);
      expect(m('Kommt das in Frage?', 'in Frage kommen'), isTrue);
    });

    test('rejects sentences without the word', () {
      expect(m('Die Hauptstadt ist groß.', 'Haus'), isFalse);
      expect(m('Wir fahren morgen.', 'gehen'), isFalse);
      expect(m('Das ist eine Frage.', 'in Frage kommen'), isFalse);
      expect(m('', 'Haus'), isFalse);
      expect(m('خانه بزرگ است.', 'Haus'), isFalse);
    });

    test('also accepts a form of the base form', () {
      expect(m('Er ging weg.', 'ging', lemma: 'gehen'), isTrue);
      expect(m('Sie geht weg.', 'ging', lemma: 'gehen'), isTrue);
    });
  });

  group('selectPracticeWords', () {
    final now = DateTime.utc(2026, 10, 20, 12);
    final a = testEntry('a', 'Apfel', ['سیب']);
    final b = testEntry('b', 'Baum', ['درخت']);
    final c = testEntry('c', 'Clown', ['دلقک']);
    final empty = testEntry('d', 'leer', []);
    final blank = testEntry('e', 'blank', ['  ']);

    List<String> pick(
      List<VocabularyEntry> entries, {
      Map<String, DateTime> last = const {},
      Set<String> struggling = const {},
      int count = 3,
    }) => [
      for (final e in selectPracticeWords(
        entries,
        lastPracticed: last,
        struggling: struggling,
        nowUtc: now,
        count: count,
        random: Random(1),
      ))
        e.id,
    ];

    test('only words with a saved meaning are used', () {
      expect(pick([empty, blank, a]), ['a']);
      expect(pick([empty, blank]), isEmpty);
    });

    test('words needing practice come first, recently practised last', () {
      final last = {
        'a': now.subtract(const Duration(hours: 1)),
        'b': now.subtract(const Duration(days: 10)),
      };
      expect(pick([a, b, c], last: last), ['c', 'b', 'a']);
      expect(pick([a, b, c], last: last, struggling: {'b'}), ['b', 'c', 'a']);
      expect(pick([a, b, c], last: last, count: 2), ['c', 'b']);
    });

    test('a difficult word recently practised still waits', () {
      final hard = testEntry('h', 'Hürde', ['مانع']);
      final marked = VocabularyEntry(
        id: hard.id,
        deckId: hard.deckId,
        original: hard.original,
        normalized: hard.normalized,
        sourceLanguage: hard.sourceLanguage,
        definitionLanguage: hard.definitionLanguage,
        sourceType: hard.sourceType,
        enrichmentStatus: hard.enrichmentStatus,
        createdAt: hard.createdAt,
        updatedAt: hard.updatedAt,
        meanings: hard.meanings,
        markedDifficultAt: now,
      );
      expect(
        pick([a, marked], last: {'h': now.subtract(const Duration(hours: 2))}),
        ['a', 'h'],
      );
      expect(pick([a, marked]), ['h', 'a']);
    });
  });

  group('SentencePracticeParser.parseExercises', () {
    String content(List<Object?> items) => jsonEncode({'items': items});

    test('accepts valid items in word order', () {
      final r = SentencePracticeParser.parseExercises(
        content([gehenItem(), hausItem()]),
        [haus, gehen],
      );
      expect(r.exercises.map((e) => e.word.entryId), ['e-haus', 'e-gehen']);
      expect(r.rejected, isEmpty);
      final ex = r.exercises.first;
      expect(ex.promptFor(SentencePracticeDirection.produce), contains('خانه'));
      expect(ex.answerFor(SentencePracticeDirection.produce), contains('Haus'));
      expect(
        ex.promptFor(SentencePracticeDirection.understand),
        contains('Haus'),
      );
    });

    test('a sentence that omits the target word is rejected', () {
      final r = SentencePracticeParser.parseExercises(
        content([
          {...hausItem(), 'german': 'Unser Garten ist sehr groß.'},
          gehenItem(),
        ]),
        [haus, gehen],
      );
      expect(r.exercises.single.word, gehen);
      expect(r.rejected, [haus]);
    });

    test('a usedForm that is not in the sentence is rejected', () {
      final r = SentencePracticeParser.parseExercises(
        content([
          {...hausItem(), 'usedForm': 'Häuser'},
          gehenItem(),
        ]),
        [haus, gehen],
      );
      expect(r.rejected, [haus]);
    });

    test('items about another word, wrong ids, duplicates and invalid '
        'fields are rejected', () {
      final cases = <Map<String, Object?>>[
        {...hausItem(), 'word': 'Maus'},
        {...hausItem(), 'id': '9'},
        {...hausItem(), 'persian': 'Unser Haus ist groß.'},
        {...hausItem(), 'german': 'خانهٔ ما بزرگ است.'},
        {...hausItem(), 'persian': 'خانهٔ ما Unser Haus بزرگ است.'},
        {...hausItem(), 'german': ''},
        {...hausItem(), 'usedForm': null},
        {...hausItem(), 'german': 'Haus ${'sehr ' * 80}'},
      ];
      for (final bad in cases) {
        final r = SentencePracticeParser.parseExercises(
          content([bad, gehenItem()]),
          [haus, gehen],
        );
        expect(r.rejected, [haus], reason: '$bad');
      }
      final dup = SentencePracticeParser.parseExercises(
        content([hausItem(), hausItem(), gehenItem()]),
        [haus, gehen],
      );
      expect(dup.rejected, [haus]);
    });

    test('an answer unusable as a whole is malformed', () {
      for (final bad in [
        '',
        'not json',
        '{"items": "x"}',
        '{"other": []}',
        content([]),
        content([
          {...hausItem(), 'german': 'Kein Wort.'},
        ]),
      ]) {
        expect(
          () => SentencePracticeParser.parseExercises(bad, [haus]),
          throwsMalformed(),
          reason: bad,
        );
      }
    });

    test('accepts JSON inside a code fence', () {
      final r = SentencePracticeParser.parseExercises(
        '```json\n${content([hausItem()])}\n```',
        [haus],
      );
      expect(r.exercises, hasLength(1));
    });
  });

  group('SentencePracticeParser.parseFeedback', () {
    test('parses valid feedback', () {
      final f = SentencePracticeParser.parseFeedback(
        jsonEncode(feedbackContent()),
      );
      expect(f.verdict, SentenceVerdict.minorErrors);
      expect(f.targetWord, TargetWordUse.correct);
      expect(f.corrections.single.kind, CorrectionKind.capitalization);
      expect(f.correctedAnswer, isNotNull);
      expect(f.verdict.outcome, SentencePracticeOutcome.minorErrors);
    });

    test('a valid alternative is not an error', () {
      final f = SentencePracticeParser.parseFeedback(
        jsonEncode(
          feedbackContent(
            verdict: 'acceptable',
            corrections: [],
            correctedAnswer: null,
            explanation: 'پاسخ شما درست است، فقط با بیانی دیگر.',
          ),
        ),
      );
      expect(f.verdict, SentenceVerdict.acceptable);
      expect(f.verdict.outcome, SentencePracticeOutcome.acceptable);
      expect(f.corrections, isEmpty);
    });

    test('rejects incomplete, invalid or contradictory feedback', () {
      final cases = [
        {...feedbackContent()}..remove('verdict'),
        feedbackContent(verdict: 'great'),
        feedbackContent(targetWord: 'maybe'),
        feedbackContent(explanation: ''),
        feedbackContent(explanation: 'Only English here.'),
        feedbackContent(verdict: 'correct', targetWord: 'missing'),
        feedbackContent(verdict: 'acceptable', targetWord: 'incorrect'),
      ];
      for (final bad in cases) {
        expect(
          () => SentencePracticeParser.parseFeedback(jsonEncode(bad)),
          throwsMalformed(),
          reason: '$bad',
        );
      }
      expect(
        () => SentencePracticeParser.parseFeedback('[1, 2]'),
        throwsMalformed(),
      );
    });

    test('drops invalid corrections and keeps at most five', () {
      final f = SentencePracticeParser.parseFeedback(
        jsonEncode(
          feedbackContent(
            corrections: [
              {'type': 'nonsense', 'original': 'a', 'corrected': 'b'},
              {'type': 'grammar', 'original': 'same', 'corrected': 'same'},
              for (var i = 0; i < 6; i++)
                {
                  'type': 'grammar',
                  'original': 'x$i',
                  'corrected': 'y$i',
                  'explanation': null,
                },
            ],
          ),
        ),
      );
      expect(f.corrections, hasLength(SentencePracticeParser.maxCorrections));
    });
  });
}
