import 'dart:convert';

import 'package:ai_wortbox/features/csv_import/data/csv_parser.dart';
import 'package:ai_wortbox/features/csv_import/domain/column_mapping.dart';
import 'package:ai_wortbox/features/csv_import/domain/csv_import_analysis.dart';
import 'package:ai_wortbox/features/csv_import/domain/csv_table.dart';
import 'package:ai_wortbox/features/export/domain/csv_exporter.dart';
import 'package:ai_wortbox/features/export/domain/export_file_sink.dart';
import 'package:ai_wortbox/features/vocabulary/domain/duplicate_detection.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/entries.dart';

VocabularyEntry rich() {
  final base = testEntry('e2', 'sich "freuen", auf', [
    'خوشحال شدن',
    'منتظر بودن',
  ]);
  return VocabularyEntry(
    id: base.id,
    deckId: base.deckId,
    original: base.original,
    normalized: base.normalized,
    sourceLanguage: base.sourceLanguage,
    definitionLanguage: base.definitionLanguage,
    sourceType: base.sourceType,
    enrichmentStatus: base.enrichmentStatus,
    createdAt: base.createdAt,
    updatedAt: base.updatedAt,
    meanings: base.meanings,
    lemma: 'freuen',
    partOfSpeech: 'Verb',
    grammarInfo: 'reflexiv; + auf (Akk.)',
    exampleSentence: 'Ich freue mich auf das Wochenende.',
    exampleTranslation: 'منتظر آخر هفته هستم.',
    notes: 'خط اول\nخط دوم',
  );
}

void main() {
  test('header row, BOM, CRLF and empty optional cells', () {
    final bytes = CsvExporter.toBytes([
      testEntry('e1', 'Haus', ['خانه']),
    ]);
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    final text = utf8.decode(bytes.skip(3).toList());
    expect(
      text,
      'word,meaning,lemma,part of speech,grammar,example,'
      'example translation,notes,tags\r\n'
      'Haus,خانه,,,,,,,\r\n',
    );
  });

  test('an empty list exports only the header', () {
    expect(CsvExporter.toCsv(const []), '${CsvExporter.headers.join(',')}\r\n');
  });

  test('quotes, commas, line breaks and edge spaces are quoted; meanings '
      'and tags joined with "; "', () {
    final csv = CsvExporter.toCsv(
      [rich(), testEntry('e3', ' padded ', [])],
      tagsByEntry: const {
        'e2': ['B1', 'Verben'],
      },
    );
    final lines = csv.split('\r\n');
    expect(
      lines[1],
      '"sich ""freuen"", auf",خوشحال شدن; منتظر بودن,freuen,Verb,'
      'reflexiv; + auf (Akk.),Ich freue mich auf das Wochenende.,'
      'منتظر آخر هفته هستم.,"خط اول\nخط دوم",B1; Verben',
    );
    expect(csv, contains('" padded ",'));
  });

  test('round trip through the CSV importer: headers are recognized, '
      'German and Persian text and tags survive', () {
    final entries = [
      testEntry('e1', 'Straße', ['خیابان']),
      rich(),
      testEntry('e4', 'Mühe', ['زحمت', 'تلاش']),
    ];
    final bytes = CsvExporter.toBytes(
      entries,
      tagsByEntry: const {
        'e2': ['B1', 'فعل‌ها'],
      },
    );
    final table = CsvParser.read(bytes);
    expect(table.encoding, CsvTextEncoding.utf8Bom);
    final mapping = HeaderRecognizer.suggest(table);
    expect(mapping.hasHeader, isTrue);
    expect(mapping.fields, [
      ImportField.original,
      ImportField.meaning,
      ImportField.lemma,
      ImportField.partOfSpeech,
      ImportField.grammarInfo,
      ImportField.exampleSentence,
      ImportField.exampleTranslation,
      ImportField.notes,
      ImportField.tags,
    ]);
    final analysis = analyzeCsvImport(
      table: table,
      mapping: mapping,
      deckId: 'other',
      existing: const [],
      strategy: DuplicateStrategy.skip,
    );
    expect(analysis.errorCount, 0);
    final drafts = analysis.rows.map((r) => r.draft).toList();
    expect(drafts.map((d) => d.original), [
      'Straße',
      'sich "freuen", auf',
      'Mühe',
    ]);
    expect(drafts.last.meanings.map((m) => m.text), ['زحمت', 'تلاش']);
    final freuen = drafts[1];
    expect(freuen.meanings.map((m) => m.text), ['خوشحال شدن', 'منتظر بودن']);
    expect(freuen.lemma, 'freuen');
    expect(freuen.partOfSpeech, 'Verb');
    expect(freuen.exampleTranslation, 'منتظر آخر هفته هستم.');
    expect(freuen.notes, 'خط اول\nخط دوم');
    expect(analysis.rows[1].tags, ['B1', 'فعل‌ها']);
    // Only meaning and tag cells are split at ";", so other fields keep it.
    expect(freuen.grammarInfo, 'reflexiv; + auf (Akk.)');
  });

  test('documented limitation: a ";" inside one meaning splits it into '
      'two meanings on re-import', () {
    final table = CsvParser.read(
      CsvExporter.toBytes([
        testEntry('e1', 'Bank', ['بانک; نیمکت']),
      ]),
    );
    final analysis = analyzeCsvImport(
      table: table,
      mapping: HeaderRecognizer.suggest(table),
      deckId: 'd',
      existing: const [],
      strategy: DuplicateStrategy.skip,
    );
    expect(analysis.rows.single.draft.meanings.map((m) => m.text), [
      'بانک',
      'نیمکت',
    ]);
  });

  test('export file names keep Persian and German, replace unsafe '
      'characters', () {
    final date = DateTime(2026, 10, 19);
    expect(
      exportFileName('Kafka: Die Verwandlung / Kap.1', date, 'csv'),
      'AI WortBox - Kafka- Die Verwandlung - Kap.1 - 2026-10-19.csv',
    );
    expect(
      exportFileName('لغت‌های سفر', date, 'apkg'),
      'AI WortBox - لغت‌های سفر - 2026-10-19.apkg',
    );
    expect(
      exportFileName('???', date, 'csv'),
      'AI WortBox - --- - 2026-10-19.csv',
    );
  });
}
