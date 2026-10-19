import 'dart:convert';

import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/features/enrichment/domain/enrichment_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/ai_fakes.dart';

void main() {
  ParsedEnrichment parse(Object content, {String original = 'ging'}) =>
      EnrichmentParser.parse(
        content is String ? content : jsonEncode(content),
        original: original,
      );

  final malformed = throwsA(
    isA<EnrichmentException>().having(
      (e) => e.error,
      'error',
      EnrichmentError.malformedResponse,
    ),
  );

  test('accepts a complete structured response', () {
    final result = parse(
      enrichmentContent(
        meanings: [
          {'text': 'رفتن', 'explanation': 'با پا یا وسیله'},
          {'text': 'گذشتن (زمان)', 'explanation': null},
        ],
        isAmbiguous: true,
      ),
    );
    expect(result.meanings.map((m) => m.text), ['رفتن', 'گذشتن (زمان)']);
    expect(result.meanings.first.explanation, 'با پا یا وسیله');
    expect(result.partOfSpeech, 'Verb');
    expect(result.grammarInfo, 'ging, ist gegangen');
    expect(result.lemma, 'gehen');
    expect(result.exampleSentence, 'Wir gehen morgen ins Kino.');
    expect(result.exampleTranslation, 'ما فردا به سینما می‌رویم.');
    expect(result.isAmbiguous, isTrue);
  });

  test('tolerates a Markdown code fence around the JSON', () {
    final fenced = '```json\n${jsonEncode(enrichmentContent())}\n```';
    expect(parse(fenced).meanings.single.text, 'رفتن');
  });

  group('malformed or unusable output', () {
    test('not JSON', () {
      expect(() => parse('Sure! gehen = رفتن'), malformed);
    });
    test('JSON but not an object', () {
      expect(() => parse('[1, 2]'), malformed);
    });
    test('truncated JSON', () {
      expect(() => parse('{"meanings": [{"te'), malformed);
    });
    test('no meanings field', () {
      expect(() => parse({'lemma': 'gehen'}), malformed);
    });
    test('meanings of the wrong type', () {
      expect(() => parse({'meanings': 'رفتن'}), malformed);
      expect(
        () => parse({
          'meanings': [42, null, true],
        }),
        malformed,
      );
    });
    test('meanings that are not Persian are rejected', () {
      expect(
        () => parse(
          enrichmentContent(
            meanings: [
              {'text': 'to go', 'explanation': null},
              {'text': 'gehen', 'explanation': null},
            ],
          ),
        ),
        malformed,
      );
    });
    test('empty or whitespace meanings', () {
      expect(
        () => parse(
          enrichmentContent(
            meanings: [
              {'text': '   ', 'explanation': null},
            ],
          ),
        ),
        malformed,
      );
    });
  });

  test('drops invalid meanings but keeps valid ones, deduplicated', () {
    final result = parse(
      enrichmentContent(
        meanings: [
          {'text': 'to go', 'explanation': null},
          {'text': 'رفتن', 'explanation': 'go'},
          {'text': ' رفتن ', 'explanation': null},
          {'text': 'raftan', 'explanation': null},
          {'text': 'رهسپار شدن', 'explanation': null},
        ],
      ),
    );
    expect(result.meanings.map((m) => m.text), ['رفتن', 'رهسپار شدن']);
    // A non-Persian explanation is dropped, the meaning kept.
    expect(result.meanings.first.explanation, isNull);
  });

  test('limits the number and length of meanings', () {
    final result = parse(
      enrichmentContent(
        meanings: [
          {'text': 'ب' * 400, 'explanation': null},
          for (var i = 0; i < 9; i++)
            {'text': 'معنی شمارهٔ $i', 'explanation': null},
        ],
      ),
    );
    expect(result.meanings, hasLength(5));
    expect(result.meanings.first.text, 'معنی شمارهٔ 0');
  });

  test('example sentence and translation are kept only as a valid pair', () {
    // Translation in German instead of Persian: both dropped.
    final wrongTranslation = parse(
      enrichmentContent(exampleTranslation: 'Wir gehen morgen ins Kino.'),
    );
    expect(wrongTranslation.exampleSentence, isNull);
    expect(wrongTranslation.exampleTranslation, isNull);

    // Example in Persian instead of German: both dropped.
    final wrongExample = parse(
      enrichmentContent(exampleSentence: 'ما فردا می‌رویم.'),
    );
    expect(wrongExample.exampleSentence, isNull);
    expect(wrongExample.exampleTranslation, isNull);

    // Missing translation: both dropped.
    final missing = parse(enrichmentContent(exampleTranslation: null));
    expect(missing.exampleSentence, isNull);
  });

  test('Persian translation keeps «» quotes, Persian digits and ZWNJ', () {
    final result = parse(
      enrichmentContent(
        exampleSentence: 'Er sagte: „Ich komme um 7 Uhr.“',
        exampleTranslation: 'او گفت: «ساعت ۷ می‌آیم.»',
      ),
    );
    expect(result.exampleSentence, 'Er sagte: „Ich komme um 7 Uhr.“');
    expect(result.exampleTranslation, 'او گفت: «ساعت ۷ می‌آیم.»');
  });

  test('lemma equal to the original, or not German, is dropped', () {
    expect(parse(enrichmentContent(lemma: 'Ging')).lemma, isNull);
    expect(parse(enrichmentContent(lemma: 'رفتن')).lemma, isNull);
    expect(parse(enrichmentContent(lemma: 'gehen')).lemma, 'gehen');
  });

  test('unknown part of speech is dropped, known ones get German labels', () {
    expect(
      parse(
        enrichmentContent(
          partOfSpeech: 'noun',
          lemma: 'Haus',
          grammarInfo: 'das Haus, -es, -¨er',
        ),
      ).partOfSpeech,
      'Nomen',
    );
    expect(
      parse(enrichmentContent(partOfSpeech: 'phrase')).partOfSpeech,
      'Redewendung',
    );
    expect(
      parse(enrichmentContent(partOfSpeech: 'gerund')).partOfSpeech,
      isNull,
    );
    expect(parse(enrichmentContent(partOfSpeech: null)).partOfSpeech, isNull);
  });

  test('control characters are removed and whitespace collapsed', () {
    final result = parse(
      enrichmentContent(
        meanings: [
          {'text': 'رف\u0000تن\n\n  کردن', 'explanation': null},
        ],
        grammarInfo: 'ging,\tist\u0007 gegangen',
      ),
    );
    expect(result.meanings.single.text, 'رفتن کردن');
    expect(result.grammarInfo, 'ging, ist gegangen');
  });

  test('isAmbiguous defaults to false for non-boolean values', () {
    final content = enrichmentContent()..['isAmbiguous'] = 'yes';
    expect(parse(content).isAmbiguous, isFalse);
  });

  test('the schema is strict: every property required, no extras', () {
    final properties = (enrichmentResponseSchema['properties']! as Map).keys
        .toSet();
    expect(enrichmentResponseSchema['required'], unorderedEquals(properties));
    expect(enrichmentResponseSchema['additionalProperties'], isFalse);
  });

  group('grammar validation (no hallucinated grammar is kept)', () {
    test('no grammar note without a word class', () {
      final r = parse(enrichmentContent(partOfSpeech: null));
      expect(r.grammarInfo, isNull);
    });

    test('a lower-case "noun" loses word class and grammar', () {
      final r = parse(
        enrichmentContent(
          partOfSpeech: 'noun',
          lemma: null,
          grammarInfo: 'der Lauf, -(e)s, Läufe',
        ),
        original: 'laufen',
      );
      expect(r.partOfSpeech, isNull);
      expect(r.grammarInfo, isNull);
    });

    test('a noun note must start with its article', () {
      final ok = parse(
        enrichmentContent(
          partOfSpeech: 'noun',
          lemma: null,
          grammarInfo: 'die Mühe, -, -n',
        ),
        original: 'Mühe',
      );
      expect(ok.grammarInfo, 'die Mühe, -, -n');
      final bad = parse(
        enrichmentContent(
          partOfSpeech: 'noun',
          lemma: null,
          grammarInfo: 'Plural: Mühen',
        ),
        original: 'Mühe',
      );
      expect(bad.partOfSpeech, 'Nomen');
      expect(bad.grammarInfo, isNull);
    });

    test('a noun-style note on a verb is dropped', () {
      final r = parse(
        enrichmentContent(partOfSpeech: 'verb', grammarInfo: 'der Gang, -es'),
      );
      expect(r.partOfSpeech, 'Verb');
      expect(r.grammarInfo, isNull);
    });

    test('a verb lemma must look like an infinitive', () {
      expect(parse(enrichmentContent(lemma: 'ging')).lemma, isNull);
      expect(parse(enrichmentContent(lemma: 'gehen')).lemma, 'gehen');
      expect(
        parse(
          enrichmentContent(lemma: 'sich freuen'),
          original: 'freute',
        ).lemma,
        'sich freuen',
      );
    });

    test('grammar notes in Persian or overly long ones are dropped', () {
      expect(
        parse(enrichmentContent(grammarInfo: 'فعل بی‌قاعده')).grammarInfo,
        isNull,
      );
      expect(
        parse(enrichmentContent(grammarInfo: 'ging, ${'x' * 300}')).grammarInfo,
        isNull,
      );
    });
  });

  group('batch JSON validation', () {
    const words = [(id: '1', original: 'ging'), (id: '2', original: 'Mühe')];
    Map<String, Object?> item(
      String id,
      String word, [
      Map<String, Object?>? c,
    ]) => {'id': id, 'word': word, ...(c ?? enrichmentContent())};
    final muehe = enrichmentContent(
      meanings: [
        {'text': 'زحمت', 'explanation': null},
      ],
      partOfSpeech: 'noun',
      grammarInfo: 'die Mühe, -, -n',
      lemma: null,
    );

    test('the batch schema requires id, word and every field, strictly', () {
      final itemSchema =
          ((batchEnrichmentResponseSchema['properties']! as Map)['items']!
                  as Map)['items']!
              as Map;
      expect(itemSchema['additionalProperties'], isFalse);
      expect(
        itemSchema['required'],
        unorderedEquals([
          'id',
          'word',
          ...enrichmentResponseSchema['required']! as List,
        ]),
      );
    });

    test('valid items are parsed per id; extra, unknown and duplicate items '
        'are ignored', () {
      final results = EnrichmentParser.parseBatch(
        jsonEncode({
          'items': [
            item('2', 'Mühe', muehe),
            item('1', 'ging'),
            item(
              '1',
              'ging',
              enrichmentContent(
                meanings: [
                  {'text': 'دوم', 'explanation': null},
                ],
              ),
            ),
            item('9', 'Haus'),
            'garbage',
          ],
        }),
        words,
      );
      expect(results.keys, unorderedEquals(['1', '2']));
      expect((results['1']! as ParsedEnrichment).meanings.first.text, 'رفتن');
      expect(
        (results['2']! as ParsedEnrichment).grammarInfo,
        'die Mühe, -, -n',
      );
    });

    test('a missing, mismatched or invalid item fails alone', () {
      final results = EnrichmentParser.parseBatch(
        jsonEncode({
          'items': [
            item('1', 'gehen'), // the wrong word for id 1
            item('2', 'Mühe', muehe),
          ],
        }),
        words,
      );
      expect(results['1'], isA<EnrichmentException>());
      expect(results['2'], isA<ParsedEnrichment>());
    });

    test('a bare array and items without ids (matched by word) are accepted; '
        'a code fence is tolerated', () {
      final results = EnrichmentParser.parseBatch(
        '```json\n${jsonEncode([
          {'word': 'ging', ...enrichmentContent()},
          {'word': 'Mühe', ...muehe},
        ])}\n```',
        words,
      );
      expect(results.values.every((r) => r is ParsedEnrichment), isTrue);
    });

    test(
      'a single-word answer without the wrapper is accepted for one word',
      () {
        final results = EnrichmentParser.parseBatch(
          jsonEncode(enrichmentContent()),
          [(id: '1', original: 'ging')],
        );
        expect(results['1'], isA<ParsedEnrichment>());
      },
    );

    test('an answer with no usable item is malformed as a whole', () {
      for (final content in [
        'not json',
        jsonEncode({'items': <Object>[]}),
        jsonEncode({
          'items': [item('1', 'Haus')],
        }),
        jsonEncode(enrichmentContent()), // two words requested
      ]) {
        expect(() => EnrichmentParser.parseBatch(content, words), malformed);
      }
    });
  });
}
