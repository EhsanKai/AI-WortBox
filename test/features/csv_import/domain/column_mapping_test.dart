import 'package:ai_wortbox/features/csv_import/data/csv_parser.dart';
import 'package:ai_wortbox/features/csv_import/domain/column_mapping.dart';
import 'package:ai_wortbox/features/csv_import/domain/csv_table.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

CsvTable table(List<List<String>> rows) => CsvTable(
  records: [
    for (final (i, r) in rows.indexed) CsvRecord(line: i + 1, cells: r),
  ],
  delimiter: ',',
  encoding: CsvTextEncoding.utf8,
  delimiterWasDetected: true,
);

const o = ImportField.original;
const m = ImportField.meaning;
const ig = ImportField.ignore;

void main() {
  group('HeaderRecognizer.recognize', () {
    test('recognizes the common English headers', () {
      expect(HeaderRecognizer.recognize('word'), o);
      expect(HeaderRecognizer.recognize('Term'), o);
      expect(HeaderRecognizer.recognize(' GERMAN '), o);
      expect(HeaderRecognizer.recognize('meaning'), m);
      expect(HeaderRecognizer.recognize('translation'), m);
      expect(HeaderRecognizer.recognize('Persian'), m);
      expect(
        HeaderRecognizer.recognize('example'),
        ImportField.exampleSentence,
      );
    });

    test('normalizes separators and recognizes multi-word headers', () {
      expect(
        HeaderRecognizer.recognize('example_translation'),
        ImportField.exampleTranslation,
      );
      expect(
        HeaderRecognizer.recognize('Part-of-Speech'),
        ImportField.partOfSpeech,
      );
    });

    test('recognizes German and Persian headers', () {
      expect(HeaderRecognizer.recognize('Wort'), o);
      expect(HeaderRecognizer.recognize('Übersetzung'), m);
      expect(HeaderRecognizer.recognize('لغت'), o);
      expect(HeaderRecognizer.recognize('معنی'), m);
      expect(
        HeaderRecognizer.recognize('ترجمهٔ مثال'),
        ImportField.exampleTranslation,
      );
    });

    test('returns null for data and unknown headers', () {
      expect(HeaderRecognizer.recognize('Haus'), isNull);
      expect(HeaderRecognizer.recognize('خانه'), isNull);
    });
  });

  group('HeaderRecognizer.suggest', () {
    test('maps recognized header columns in any order', () {
      final mapping = HeaderRecognizer.suggest(
        CsvParser.read(csvFixture('persian_headers.csv')),
      );
      expect(mapping.hasHeader, isTrue);
      expect(mapping.fields, [
        m,
        o,
        ImportField.exampleTranslation,
        ImportField.exampleSentence,
      ]);
    });

    test('allows several meaning columns, keeps the first word column', () {
      final mapping = HeaderRecognizer.suggest(
        table([
          ['word', 'german', 'meaning', 'translation', 'whatever'],
        ]),
      );
      expect(mapping.fields, [o, ig, m, m, ig]);
    });

    test('assigns the word to the first free column if no word header', () {
      final mapping = HeaderRecognizer.suggest(
        table([
          ['Begriff', 'meaning'],
          ['Haus', 'خانه'],
        ]),
      );
      expect(mapping.hasHeader, isTrue);
      expect(mapping.fields, [o, m]);
    });

    test('without a header, picks columns by script', () {
      final mapping = HeaderRecognizer.suggest(
        CsvParser.read(csvFixture('persian_first.csv')),
      );
      expect(mapping.hasHeader, isFalse);
      expect(mapping.fields, [m, o]);
    });

    test('without a header or script hints, uses columns 1 and 2', () {
      final mapping = HeaderRecognizer.suggest(
        table([
          ['1', '2', '3'],
        ]),
      );
      expect(mapping.fields, [o, m, ig]);
    });

    test('single-column files map the only column to the word', () {
      final mapping = HeaderRecognizer.suggest(
        table([
          ['Haus'],
          ['Baum'],
        ]),
      );
      expect(mapping.fields, [o]);
    });
  });

  group('ColumnMapping', () {
    const mapping = ColumnMapping(hasHeader: true, fields: [o, m, ig]);

    test('moving a single-valued field clears its previous column', () {
      expect(mapping.withField(2, o).fields, [ig, m, o]);
    });

    test('meaning may be assigned to several columns', () {
      expect(mapping.withField(2, m).fields, [o, m, m]);
    });

    test('extends the field list for new columns', () {
      expect(mapping.withField(4, ImportField.notes).fields, [
        o,
        m,
        ig,
        ig,
        ImportField.notes,
      ]);
    });

    test('swaps word and meaning columns', () {
      expect(mapping.swapOriginalAndMeaning().fields, [m, o, ig]);
    });
  });
}
