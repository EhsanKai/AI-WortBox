import 'package:ai_wortbox/features/csv_import/data/csv_parser.dart';
import 'package:ai_wortbox/features/csv_import/domain/column_mapping.dart';
import 'package:ai_wortbox/features/csv_import/domain/csv_import_analysis.dart';
import 'package:ai_wortbox/features/vocabulary/domain/duplicate_detection.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/entries.dart';
import '../../../helpers/fixtures.dart';

CsvImportAnalysis analyze(
  String fixture, {
  List<VocabularyEntry> existing = const [],
  DuplicateStrategy strategy = DuplicateStrategy.skip,
  ColumnMapping Function(ColumnMapping)? adjust,
}) {
  final table = CsvParser.read(csvFixture(fixture));
  var mapping = HeaderRecognizer.suggest(table);
  if (adjust != null) mapping = adjust(mapping);
  return analyzeCsvImport(
    table: table,
    mapping: mapping,
    deckId: 'deck',
    existing: existing,
    strategy: strategy,
  );
}

void main() {
  test('splitMeanings splits on ; ؛ | and line breaks, not commas', () {
    expect(splitMeanings('خانه؛ منزل | سرا; کاشانه'), [
      'خانه',
      'منزل',
      'سرا',
      'کاشانه',
    ]);
    expect(splitMeanings('بزرگ، عظیم'), ['بزرگ، عظیم']);
    expect(splitMeanings('  '), isEmpty);
  });

  test('basic_comma.csv: all fields, multiple meanings, multi-line cells', () {
    final analysis = analyze('basic_comma.csv');
    expect(analysis.rows, hasLength(4));
    expect(analysis.errorCount, 0);
    expect(analysis.createCount, 4);

    final aufgeben = analysis.rows[1].draft;
    expect(aufgeben.original, 'aufgeben');
    expect(aufgeben.meanings.map((m) => m.text), ['تسلیم شدن', 'ترک کردن']);
    expect(aufgeben.exampleSentence, 'Er gibt nie auf, egal was passiert.');
    expect(aufgeben.exampleTranslation, 'او هرگز تسلیم نمی‌شود.');
    expect(aufgeben.sourceType, VocabularySourceType.csv);

    // A multi-line example is collapsed to one line for the example field.
    expect(
      analysis.rows[2].draft.exampleSentence,
      'Sie gibt sich Mühe. Jeden Tag.',
    );
    expect(analysis.rows.map((r) => r.line), [2, 3, 4, 6]);
  });

  test(
    'excel_semicolon_bom.csv: German headers and pipe-separated meanings',
    () {
      final analysis = analyze('excel_semicolon_bom.csv');
      expect(analysis.rows.map((r) => r.draft.original), [
        'der Tisch',
        'schön',
        'Übung',
      ]);
      expect(analysis.rows[1].draft.meanings.map((m) => m.text), [
        'زیبا',
        'قشنگ',
      ]);
      expect(analysis.rows[0].draft.notes, 'Plural: Tische');
    },
  );

  test('malformed_rows.csv: row-level issues with line numbers', () {
    final analysis = analyze('malformed_rows.csv');
    final issues = {for (final r in analysis.invalidRows) r.line: r.issues};
    expect(issues, {
      3: {ImportRowIssue.missingWord},
      5: {ImportRowIssue.wordTooLong},
    });
    // Valid rows: gut, kurz (no meaning), lang (extra columns ignored), schnell.
    expect(analysis.rows.where((r) => r.isValid).map((r) => r.draft.original), [
      'gut',
      'kurz',
      'lang',
      'schnell',
    ]);
    expect(analysis.createCount, 4);
  });

  test('duplicates.csv with each strategy', () {
    final existing = [
      testEntry('haus', 'Haus', ['خانه']),
    ];
    final skip = analyze('duplicates.csv', existing: existing);
    expect((skip.createCount, skip.mergeCount, skip.skipCount), (2, 0, 4));

    final merge = analyze(
      'duplicates.csv',
      existing: existing,
      strategy: DuplicateStrategy.mergeMeanings,
    );
    expect((merge.createCount, merge.mergeCount, merge.skipCount), (2, 2, 2));

    final separate = analyze(
      'duplicates.csv',
      existing: existing,
      strategy: DuplicateStrategy.keepSeparate,
    );
    expect(
      (separate.createCount, separate.mergeCount, separate.skipCount),
      (4, 0, 2),
    );
  });

  test('detects swapped language columns and swapping fixes it', () {
    final wrong = analyze(
      'persian_first.csv',
      adjust: (m) => m.swapOriginalAndMeaning(),
    );
    expect(wrong.languagesLookSwapped, isTrue);

    final right = analyze('persian_first.csv');
    expect(right.languagesLookSwapped, isFalse);
    expect(right.rows.first.draft.original, 'Haus');
    expect(right.rows.first.draft.meanings.single.text, 'خانه');
  });

  test('turning off the header imports the first row as data', () {
    final analysis = analyze(
      'tab_no_header.tsv',
      adjust: (m) => m.withHeader(true),
    );
    expect(analysis.rows.map((r) => r.draft.original), ['Birne', 'laufen']);
    expect(analyze('tab_no_header.tsv').rows, hasLength(3));
  });

  test('candidates include only valid rows', () {
    final analysis = analyze('malformed_rows.csv');
    // Blank lines are not records; the all-empty ",," row is counted but dropped.
    expect(analysis.candidates.map((c) => c.rowNumber), [1, 4, 5, 7]);
  });
}
