import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/features/anki/data/anki_package_reader.dart';
import 'package:ai_wortbox/features/anki/data/anki_package_writer.dart';
import 'package:ai_wortbox/features/anki/data/anki_sqlite.dart';
import 'package:ai_wortbox/features/anki/domain/anki_html.dart';
import 'package:ai_wortbox/features/csv_import/domain/column_mapping.dart';
import 'package:ai_wortbox/features/csv_import/domain/csv_import_analysis.dart';
import 'package:ai_wortbox/features/csv_import/domain/csv_table.dart';
import 'package:ai_wortbox/features/vocabulary/domain/duplicate_detection.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/entries.dart';
import '../../helpers/fixtures.dart';

Matcher failsWith(AnkiImportError error) =>
    throwsA(isA<AnkiImportException>().having((e) => e.error, 'error', error));

Uint8List zip(Map<String, List<int>> files) {
  final archive = Archive();
  files.forEach((name, bytes) => archive.add(ArchiveFile.bytes(name, bytes)));
  return Uint8List.fromList(ZipEncoder().encodeBytes(archive));
}

void main() {
  group('AnkiHtml', () {
    test('field HTML becomes plain text', () {
      expect(AnkiHtml.toText('خانه<br>منزل'), 'خانه\nمنزل');
      expect(AnkiHtml.toText('<b>gehen</b>'), 'gehen');
      expect(AnkiHtml.toText('رفتن&nbsp;/ راه رفتن'), 'رفتن / راه رفتن');
      expect(AnkiHtml.toText('زحمت [sound:muehe.mp3]'), 'زحمت');
      expect(AnkiHtml.toText('<div>a</div><div>b</div>'), 'a\nb');
      expect(
        AnkiHtml.toText('{{c1::Haus::Gebäude}} ist groß'),
        'Haus ist groß',
      );
      expect(AnkiHtml.toText('&lt;x&gt; &amp; &#228; &#x00FC;'), '<x> & ä ü');
      expect(AnkiHtml.toText('<img src="a.jpg">'), '');
      expect(AnkiHtml.toText('می&zwnj;روم'), 'می‌روم');
    });

    test('plain text becomes escaped field HTML and back', () {
      const text = 'a < b & "c"\nخط دوم';
      expect(AnkiHtml.fromText(text), 'a &lt; b &amp; &quot;c&quot;<br>خط دوم');
      expect(AnkiHtml.toText(AnkiHtml.fromText(text)), text);
    });
  });

  group('reading packages written by Anki', () {
    for (final name in ['modern_anki21b.apkg', 'legacy_anki21.apkg']) {
      test('$name: notes of all note types, plain text, tags', () {
        final table = AnkiPackageReader.read(ankiFixture(name));
        expect(table.source, CsvTableSource.ankiPackage);
        // Basic and "Basic (and reversed card)" share Front/Back.
        expect(table.records.first.cells, ['Front', 'Back', 'tags']);
        final rows = table.records.skip(1).map((r) => r.cells).toList();
        expect(rows, [
          ['das Haus', 'خانه\nمنزل', 'A1; Wohnen'],
          ['gehen', 'رفتن / راه رفتن', ''],
          ['die Mühe', 'زحمت', 'A2'],
          ['sich freuen', 'خوشحال شدن', 'Verben'],
          ['das Haus', 'خانه', ''],
          ['', 'بدون لغت', ''],
        ]);
      });
    }

    test('the notes go through the normal import analysis: mapping, '
        'meanings, tags, duplicates and invalid rows', () {
      final table = AnkiPackageReader.read(ankiFixture('modern_anki21b.apkg'));
      final mapping = HeaderRecognizer.suggest(table);
      expect(mapping.hasHeader, isTrue);
      expect(mapping.fields, [
        ImportField.original,
        ImportField.meaning,
        ImportField.tags,
      ]);
      final analysis = analyzeCsvImport(
        table: table,
        mapping: mapping,
        deckId: 'deck',
        existing: [
          testEntry('old', 'die Mühe', ['زحمت']),
        ],
        strategy: DuplicateStrategy.skip,
      );
      final haus = analysis.rows.first;
      expect(haus.draft.meanings.map((m) => m.text), ['خانه', 'منزل']);
      expect(haus.tags, ['A1', 'Wohnen']);
      expect(analysis.createCount, 3); // Haus, gehen, sich freuen
      expect(analysis.skipCount, 2); // Mühe exists; second Haus redundant
      expect(analysis.errorCount, 1); // empty front
      expect(analysis.invalidRows.single.issues, {ImportRowIssue.missingWord});
    });
  });

  group('invalid input', () {
    test('not a ZIP file', () {
      expect(
        () => AnkiPackageReader.read(Uint8List.fromList(utf8.encode('a,b'))),
        failsWith(AnkiImportError.notAnkiPackage),
      );
      expect(
        AnkiPackageReader.looksLikePackage(Uint8List.fromList([1, 2])),
        isFalse,
      );
    });

    test('a ZIP without a collection', () {
      expect(
        () => AnkiPackageReader.read(zip({'media': utf8.encode('{}')})),
        failsWith(AnkiImportError.notAnkiPackage),
      );
    });

    test('a damaged collection', () {
      expect(
        () => AnkiPackageReader.read(
          zip({'collection.anki2': utf8.encode('not a database')}),
        ),
        failsWith(AnkiImportError.unsupportedFormat),
      );
    });

    test('only the "please update Anki" placeholder is not imported', () {
      final real = ZipDecoder().decodeBytes(ankiFixture('modern_anki21b.apkg'));
      final placeholder = real.findFile('collection.anki2')!.readBytes()!;
      expect(
        () => AnkiPackageReader.read(zip({'collection.anki2': placeholder})),
        failsWith(AnkiImportError.unsupportedFormat),
      );
    });

    test('a package without notes', () {
      final empty = AnkiPackageWriter.build(
        deckName: 'Leer',
        entries: const [],
        nowUtc: DateTime.utc(2026, 10, 17),
      );
      expect(
        () => AnkiPackageReader.read(empty),
        failsWith(AnkiImportError.noNotes),
      );
    });
  });

  group('writing packages', () {
    final now = DateTime.utc(2026, 10, 17, 9);
    final entries = [
      testEntry('e1', 'das Haus', ['خانه', 'منزل']),
      VocabularyEntry(
        id: 'e2',
        deckId: 'deck',
        original: 'sich Mühe geben',
        normalized: 'sich mühe geben',
        lemma: 'Mühe',
        sourceLanguage: testEntry('x', 'x', []).sourceLanguage,
        definitionLanguage: testEntry('x', 'x', []).definitionLanguage,
        sourceType: VocabularySourceType.image,
        enrichmentStatus: EnrichmentStatus.ready,
        createdAt: now,
        updatedAt: now,
        meanings: const [VocabularyMeaning('تلاش کردن <زیاد> & "جدی"')],
        exampleSentence: 'Er gibt sich große Mühe.',
        exampleTranslation: 'او خیلی تلاش می‌کند.',
        grammarInfo: 'reflexiv',
        sourceContext: 'Sie gab sich Mühe, nicht zu lachen.',
      ),
    ];
    const tags = {
      'e1': ['A1', 'Kafka Buch'],
    };

    test('structure: legacy collection (schema 11) and empty media map', () {
      final bytes = AnkiPackageWriter.build(
        deckName: 'Kafka — Verwandlung',
        entries: entries,
        tagsByEntry: tags,
        nowUtc: now,
      );
      final archive = ZipDecoder().decodeBytes(bytes);
      expect(archive.files.map((f) => f.name), ['collection.anki2', 'media']);
      expect(utf8.decode(archive.findFile('media')!.readBytes()!), '{}');

      final collection = archive.findFile('collection.anki2')!.readBytes()!;
      withMemoryDatabase((db) {
        expect(db.select('SELECT ver FROM col').single['ver'], 11);
        final notes = db.select(
          'SELECT guid, mid, tags, flds, sfld, csum FROM notes ORDER BY id',
        );
        expect(notes, hasLength(2));
        expect(notes.first['guid'], 'aiwortbox-e1');
        expect(notes.first['mid'], AnkiPackageWriter.noteTypeId);
        expect(notes.first['tags'], ' A1 Kafka_Buch ');
        expect((notes.first['flds'] as String).split('\u001f').take(2), [
          'das Haus',
          'خانه<br>منزل',
        ]);
        // The same checksum Anki itself stored for "das Haus".
        expect(notes.first['csum'], 2447274580);
        expect(
          (notes.last['flds'] as String).split('\u001f')[1],
          'تلاش کردن &lt;زیاد&gt; &amp; &quot;جدی&quot;',
        );
        final cards = db.select('SELECT nid, ord, type, queue FROM cards');
        expect(cards, hasLength(2));
        expect(cards.every((c) => c['type'] == 0 && c['queue'] == 0), isTrue);
        final models = jsonDecode(
          db.select('SELECT models FROM col').single['models'] as String,
        ) as Map<String, dynamic>;
        final model = models.values.single as Map<String, dynamic>;
        expect([
          for (final f in (model['flds'] as List).cast<Map<String, dynamic>>())
            f['name'],
        ], AnkiPackageWriter.fields);
        final decks = jsonDecode(
          db.select('SELECT decks FROM col').single['decks'] as String,
        ) as Map<String, dynamic>;
        expect(
          decks.values.map((d) => (d as Map)['name']),
          containsAll(['Default', 'Kafka — Verwandlung']),
        );
      }, initial: Uint8List.fromList(collection));
    });

    test('round trip: an exported package is read back and mapped '
        'automatically, with Persian, German and tags intact', () {
      final table = AnkiPackageReader.read(
        AnkiPackageWriter.build(
          deckName: 'Deck',
          entries: entries,
          tagsByEntry: tags,
          nowUtc: now,
        ),
      );
      final mapping = HeaderRecognizer.suggest(table);
      final analysis = analyzeCsvImport(
        table: table,
        mapping: mapping,
        deckId: 'deck',
        existing: const [],
        strategy: DuplicateStrategy.skip,
      );
      final drafts = analysis.rows.map((r) => r.draft).toList();
      expect(drafts.map((d) => d.original), ['das Haus', 'sich Mühe geben']);
      expect(drafts.first.meanings.map((m) => m.text), ['خانه', 'منزل']);
      expect(analysis.rows.first.tags, ['A1', 'Kafka_Buch']);
      final muehe = drafts.last;
      expect(muehe.meanings.single.text, 'تلاش کردن <زیاد> & "جدی"');
      expect(muehe.lemma, 'Mühe');
      expect(muehe.exampleSentence, 'Er gibt sich große Mühe.');
      expect(muehe.exampleTranslation, 'او خیلی تلاش می‌کند.');
      expect(muehe.grammarInfo, 'reflexiv');
    });

    // Opt-in: writes a sample package and the expected result for the
    // compatibility check with the official Anki importer
    // (tool/anki/validate_apkg.py). Nothing is written otherwise.
    final outDir = Platform.environment['ANKI_EXPORT_DIR'];
    test('writes a sample for the external Anki check', () {
      final dir = Directory(outDir!)..createSync(recursive: true);
      File('${dir.path}/sample.apkg').writeAsBytesSync(
        AnkiPackageWriter.build(
          deckName: 'AI WortBox — Test',
          entries: entries,
          tagsByEntry: tags,
          nowUtc: now,
        ),
      );
      File('${dir.path}/sample.expected.json').writeAsStringSync(
        jsonEncode({
          'deck': 'AI WortBox — Test',
          'note_type': AnkiPackageWriter.noteTypeName,
          'fields': AnkiPackageWriter.fields,
          'notes': [
            {
              'fields': {
                'German': 'das Haus',
                'Meaning': 'خانه<br>منزل',
                'Lemma': '',
              },
              'tags': ['A1', 'Kafka_Buch'],
            },
            {
              'fields': {
                'German': 'sich Mühe geben',
                'Meaning': 'تلاش کردن &lt;زیاد&gt; &amp; &quot;جدی&quot;',
                'Lemma': 'Mühe',
                'Example': 'Er gibt sich große Mühe.',
                'Example translation': 'او خیلی تلاش می‌کند.',
                'Grammar': 'reflexiv',
                'Context': 'Sie gab sich Mühe, nicht zu lachen.',
              },
              'tags': <String>[],
            },
          ],
        }),
      );
    }, skip: outDir == null ? 'Set ANKI_EXPORT_DIR to write the sample' : null);
  });
}
