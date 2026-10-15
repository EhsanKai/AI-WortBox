import 'dart:convert';
import 'dart:typed_data';

import 'package:ai_wortbox/core/config/app_config.dart';
import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/features/csv_import/data/csv_parser.dart';
import 'package:ai_wortbox/features/csv_import/domain/csv_table.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fixtures.dart';

Uint8List bytes(String text) => Uint8List.fromList(utf8.encode(text));

Matcher throwsCsv(CsvFormatError error, {int? line}) => throwsA(
  isA<CsvFormatException>()
      .having((e) => e.error, 'error', error)
      .having((e) => e.line, 'line', line),
);

List<List<String>> cells(List<CsvRecord> records) => [
  for (final r in records) r.cells,
];

void main() {
  group('decode', () {
    test('plain UTF-8 keeps Persian and German text intact', () {
      final (text, encoding) = CsvParser.decode(bytes('Mädchen,دختر'));
      expect(text, 'Mädchen,دختر');
      expect(encoding, CsvTextEncoding.utf8);
    });

    test('strips a UTF-8 BOM', () {
      final (text, encoding) = CsvParser.decode(
        Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode('word')]),
      );
      expect(text, 'word');
      expect(encoding, CsvTextEncoding.utf8Bom);
    });

    test('decodes UTF-16 LE with BOM', () {
      final table = CsvParser.read(csvFixture('utf16le_bom.txt'));
      expect(table.encoding, CsvTextEncoding.utf16le);
      expect(table.delimiter, '\t');
      expect(cells(table.records), [
        ['word', 'meaning'],
        ['Fenster', 'پنجره'],
      ]);
    });

    test('rejects non-UTF-8 input instead of guessing', () {
      expect(
        () => CsvParser.read(csvFixture('latin1.csv')),
        throwsCsv(CsvFormatError.unsupportedEncoding),
      );
    });

    test('rejects UTF-16 without BOM (NUL bytes)', () {
      expect(
        () => CsvParser.decode(Uint8List.fromList([0x41, 0x00, 0x42, 0x00])),
        throwsCsv(CsvFormatError.unsupportedEncoding),
      );
    });

    test('rejects empty and whitespace-only files', () {
      expect(
        () => CsvParser.decode(Uint8List(0)),
        throwsCsv(CsvFormatError.empty),
      );
      expect(
        () => CsvParser.decode(bytes(' \r\n\n ')),
        throwsCsv(CsvFormatError.empty),
      );
    });

    test('rejects files above the size limit', () {
      expect(
        () => CsvParser.decode(Uint8List(AppConfig.maxCsvBytes + 1)),
        throwsCsv(CsvFormatError.tooLarge),
      );
    });
  });

  group('parse', () {
    test('handles quoted delimiters, escaped quotes and line breaks', () {
      final records = CsvParser.parse(
        'a,"b, c","say ""hi""","line1\r\nline2"\nx,y,z,w',
        ',',
      );
      expect(cells(records), [
        ['a', 'b, c', 'say "hi"', 'line1\nline2'],
        ['x', 'y', 'z', 'w'],
      ]);
      expect(records.map((r) => r.line), [1, 3]);
    });

    test('supports LF, CRLF and CR line endings', () {
      expect(cells(CsvParser.parse('a\nb\r\nc\rd', ',')), [
        ['a'],
        ['b'],
        ['c'],
        ['d'],
      ]);
    });

    test('skips blank lines but keeps physical line numbers', () {
      final records = CsvParser.parse('a,1\n\n\nb,2\n', ',');
      expect(cells(records), [
        ['a', '1'],
        ['b', '2'],
      ]);
      expect(records.map((r) => r.line), [1, 4]);
    });

    test('keeps rows of empty cells and short rows', () {
      expect(cells(CsvParser.parse(',,\nonly', ',')), [
        ['', '', ''],
        ['only'],
      ]);
    });

    test('ignores spaces around quoted fields', () {
      expect(cells(CsvParser.parse('a,  "b c"  ,d', ',')), [
        ['a', 'b c', 'd'],
      ]);
    });

    test('keeps stray quotes inside unquoted fields as text', () {
      expect(cells(CsvParser.parse('5" screen,x', ',')), [
        ['5" screen', 'x'],
      ]);
    });

    test('reports an unterminated quote with its line', () {
      expect(
        () => CsvParser.read(csvFixture('unterminated_quote.csv')),
        throwsCsv(CsvFormatError.unterminatedQuote, line: 3),
      );
    });

    test('limits the number of rows', () {
      final text = List.filled(AppConfig.maxCsvRows + 2, 'a').join('\n');
      expect(
        () => CsvParser.parse(text, ','),
        throwsCsv(CsvFormatError.tooManyRows),
      );
      // Header + maxCsvRows data rows is allowed.
      expect(
        CsvParser.parse(
          List.filled(AppConfig.maxCsvRows + 1, 'a').join('\n'),
          ',',
        ),
        hasLength(AppConfig.maxCsvRows + 1),
      );
    });
  });

  group('delimiter detection', () {
    test('detects comma, semicolon, tab and pipe', () {
      expect(CsvParser.detectDelimiter('a,b\nc,d'), ',');
      expect(CsvParser.detectDelimiter('a;b\nc;d'), ';');
      expect(CsvParser.detectDelimiter('a\tb\nc\td'), '\t');
      expect(CsvParser.detectDelimiter('a|b\nc|d'), '|');
    });

    test('is not fooled by commas inside quoted semicolon fields', () {
      expect(
        CsvParser.detectDelimiter('word;meaning\n"a, b, c";x\n"d, e";y'),
        ';',
      );
    });

    test('prefers the delimiter with consistent column counts', () {
      // Semicolons appear in text, but commas split every row in two.
      expect(
        CsvParser.detectDelimiter('Haus,خانه; منزل\nBaum,درخت\nAuto,ماشین'),
        ',',
      );
    });

    test('falls back to comma for single-column files', () {
      expect(CsvParser.detectDelimiter('Haus\nBaum\n'), ',');
    });

    test('honors an Excel sep= line and skips it', () {
      final table = CsvParser.read(csvFixture('sep_hint.csv'));
      expect(table.delimiter, ';');
      expect(table.delimiterWasDetected, isFalse);
      expect(cells(table.records), [
        ['word', 'meaning'],
        ['Geld', 'پول'],
      ]);
      expect(table.records.first.line, 2);
    });

    test('an explicit delimiter overrides detection', () {
      final table = CsvParser.read(bytes('a;b,c\n'), delimiter: ',');
      expect(cells(table.records), [
        ['a;b', 'c'],
      ]);
      expect(table.delimiterWasDetected, isFalse);
    });
  });

  group('fixtures', () {
    test('basic_comma.csv', () {
      final table = CsvParser.read(csvFixture('basic_comma.csv'));
      expect(table.delimiter, ',');
      expect(table.encoding, CsvTextEncoding.utf8);
      expect(table.records, hasLength(5));
      expect(table.records[2].cells[2], 'Er gibt nie auf, egal was passiert.');
      expect(table.records[3].cells[2], 'Sie gibt sich Mühe.\nJeden Tag.');
      expect(table.records[4].line, 6);
    });

    test('excel_semicolon_bom.csv', () {
      final table = CsvParser.read(csvFixture('excel_semicolon_bom.csv'));
      expect(table.encoding, CsvTextEncoding.utf8Bom);
      expect(table.delimiter, ';');
      expect(table.records.first.cells.first, 'Wort');
      expect(table.columnCount, 4);
    });

    test('tab_no_header.tsv', () {
      final table = CsvParser.read(csvFixture('tab_no_header.tsv'));
      expect(table.delimiter, '\t');
      expect(cells(table.records).first, ['Apfel', 'سیب']);
    });
  });
}
