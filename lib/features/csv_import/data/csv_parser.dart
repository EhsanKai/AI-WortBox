import 'dart:convert';
import 'dart:typed_data';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../domain/csv_table.dart';

/// Decodes and parses CSV files (RFC 4180 with common real-world variations).
///
/// - Encodings: UTF-8, UTF-8 with BOM, UTF-16 LE/BE with BOM. Other encodings
///   are rejected rather than guessed, so Persian text is never corrupted.
/// - Delimiters: `,` `;` tab `|`, auto-detected, or given by an Excel
///   `sep=;` first line, or chosen by the caller.
/// - Quoted fields may contain delimiters, `""` escapes and line breaks.
/// - Line endings: `\n`, `\r\n` and `\r`. Blank lines are skipped.
/// - Lenient on stray quotes inside unquoted fields (kept as text), strict on
///   an unterminated quoted field (reported with its line number).
abstract final class CsvParser {
  static const candidateDelimiters = [',', ';', '\t', '|'];

  static final _sepHint = RegExp(r'^sep=(.)\r?\n?', caseSensitive: false);

  /// Decodes and parses [bytes]. When [delimiter] is null it is taken from a
  /// `sep=` hint or auto-detected.
  static CsvTable read(Uint8List bytes, {String? delimiter}) {
    final (text, encoding) = decode(bytes);
    var body = text;
    String? chosen = delimiter;
    var detected = false;

    final hint = _sepHint.firstMatch(body);
    if (hint != null) {
      body = body.substring(hint.end);
      chosen ??= hint.group(1);
    }
    if (chosen == null) {
      chosen = detectDelimiter(body);
      detected = true;
    }

    final records = parse(body, chosen, firstLine: hint == null ? 1 : 2);
    if (records.isEmpty) throw const CsvFormatException(CsvFormatError.empty);
    return CsvTable(
      records: records,
      delimiter: chosen,
      encoding: encoding,
      delimiterWasDetected: detected,
    );
  }

  /// Decodes [bytes] to text. Throws [CsvFormatException] for empty, too
  /// large or non-Unicode input.
  static (String, CsvTextEncoding) decode(Uint8List bytes) {
    if (bytes.length > AppConfig.maxCsvBytes) {
      throw const CsvFormatException(CsvFormatError.tooLarge);
    }

    final String text;
    final CsvTextEncoding encoding;
    if (_startsWith(bytes, const [0xEF, 0xBB, 0xBF])) {
      text = _utf8(bytes.sublist(3));
      encoding = CsvTextEncoding.utf8Bom;
    } else if (_startsWith(bytes, const [0xFF, 0xFE])) {
      text = _utf16(bytes.sublist(2), littleEndian: true);
      encoding = CsvTextEncoding.utf16le;
    } else if (_startsWith(bytes, const [0xFE, 0xFF])) {
      text = _utf16(bytes.sublist(2), littleEndian: false);
      encoding = CsvTextEncoding.utf16be;
    } else {
      // NUL bytes in "UTF-8" almost always mean UTF-16 without a BOM.
      if (bytes.contains(0)) {
        throw const CsvFormatException(CsvFormatError.unsupportedEncoding);
      }
      text = _utf8(bytes);
      encoding = CsvTextEncoding.utf8;
    }

    if (text.trim().isEmpty) {
      throw const CsvFormatException(CsvFormatError.empty);
    }
    return (text, encoding);
  }

  /// Picks the candidate delimiter that splits the first records into the
  /// most consistent number (> 1) of columns. Falls back to `,` (a
  /// single-column file).
  static String detectDelimiter(String text) {
    final sample = text.length > 64 * 1024
        ? text.substring(0, 64 * 1024)
        : text;
    String best = ',';
    var bestScore = 0.0;
    var bestColumns = 1;
    for (final delimiter in candidateDelimiters) {
      final records = parse(
        sample,
        delimiter,
        maxRecords: 30,
        allowUnterminated: true,
      );
      if (records.isEmpty) continue;
      final counts = <int, int>{};
      for (final r in records) {
        counts[r.cells.length] = (counts[r.cells.length] ?? 0) + 1;
      }
      final mode = counts.entries.reduce(
        (a, b) =>
            b.value > a.value || (b.value == a.value && b.key > a.key) ? b : a,
      );
      if (mode.key < 2) continue;
      final score = mode.value / records.length;
      if (score > bestScore || (score == bestScore && mode.key > bestColumns)) {
        best = delimiter;
        bestScore = score;
        bestColumns = mode.key;
      }
    }
    return best;
  }

  /// Parses [text] into records using [delimiter].
  ///
  /// [firstLine] is the physical line number of the first character of
  /// [text]. With [allowUnterminated] a trailing open quote ends the last
  /// record instead of throwing (used on truncated samples).
  static List<CsvRecord> parse(
    String text,
    String delimiter, {
    int firstLine = 1,
    int? maxRecords,
    bool allowUnterminated = false,
  }) {
    assert(delimiter.isNotEmpty);
    final records = <CsvRecord>[];
    var cells = <String>[];
    final field = StringBuffer();
    var line = firstLine;
    var recordLine = firstLine;
    var inQuotes = false;
    var fieldQuoted = false;
    var afterClosingQuote = false;
    var quoteLine = firstLine;

    void endField() {
      cells.add(field.toString());
      field.clear();
      fieldQuoted = false;
      afterClosingQuote = false;
    }

    void endRecord() {
      final quoted = fieldQuoted;
      endField();
      final blank = cells.length == 1 && cells.first.isEmpty && !quoted;
      if (!blank) {
        if (records.length >= AppConfig.maxCsvRows + 1) {
          throw const CsvFormatException(CsvFormatError.tooManyRows);
        }
        records.add(CsvRecord(line: recordLine, cells: cells));
      }
      cells = <String>[];
    }

    var i = 0;
    while (i < text.length) {
      if (maxRecords != null && records.length >= maxRecords) break;
      final c = text[i];

      if (inQuotes) {
        if (c == '"') {
          if (i + 1 < text.length && text[i + 1] == '"') {
            field.write('"');
            i += 2;
            continue;
          }
          inQuotes = false;
          afterClosingQuote = true;
        } else if (c == '\r' || c == '\n') {
          // Normalize line breaks inside quoted fields to \n.
          if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
          field.write('\n');
          line++;
        } else {
          field.write(c);
        }
        i++;
        continue;
      }

      if (text.startsWith(delimiter, i)) {
        endField();
        i += delimiter.length;
        continue;
      }
      if (c == '\r' || c == '\n') {
        endRecord();
        if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
        i++;
        line++;
        recordLine = line;
        continue;
      }
      if (c == '"' && !fieldQuoted && field.toString().trim().isEmpty) {
        // Opening quote (leading spaces before it are ignored).
        field.clear();
        inQuotes = true;
        fieldQuoted = true;
        quoteLine = line;
        i++;
        continue;
      }
      if (afterClosingQuote && (c == ' ' || c == '\t')) {
        // Spaces between a closing quote and the delimiter are ignored.
        i++;
        continue;
      }
      // Anything else (including stray quotes) is literal text.
      field.write(c);
      i++;
    }

    if (inQuotes && !allowUnterminated) {
      throw CsvFormatException(
        CsvFormatError.unterminatedQuote,
        line: quoteLine,
      );
    }
    if (maxRecords == null || records.length < maxRecords) {
      if (field.isNotEmpty || cells.isNotEmpty || fieldQuoted) endRecord();
    }
    return records;
  }

  static bool _startsWith(Uint8List bytes, List<int> prefix) {
    if (bytes.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }

  static String _utf8(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      throw const CsvFormatException(CsvFormatError.unsupportedEncoding);
    }
  }

  static String _utf16(Uint8List bytes, {required bool littleEndian}) {
    if (bytes.length.isOdd) {
      throw const CsvFormatException(CsvFormatError.unsupportedEncoding);
    }
    final data = ByteData.sublistView(bytes);
    final units = List<int>.generate(
      bytes.length ~/ 2,
      (i) => data.getUint16(i * 2, littleEndian ? Endian.little : Endian.big),
    );
    return String.fromCharCodes(units);
  }
}
