import 'dart:convert';
import 'dart:typed_data';

import '../../vocabulary/domain/vocabulary_entry.dart';

/// Writes vocabulary as CSV in the format the CSV importer reads back
/// without manual column mapping.
///
/// - UTF-8 with a byte-order mark (so spreadsheet apps detect UTF-8 and show
///   Persian and German correctly), comma-separated, CRLF line endings,
///   RFC 4180 quoting.
/// - Columns: [headers]. Several meanings or tags in one cell are separated
///   by `"; "`.
///
/// This is a vocabulary exchange file, not a backup: it contains no review
/// history, difficult marks, statistics, settings, meaning explanations,
/// sentence context or API key.
abstract final class CsvExporter {
  static const headers = [
    'word',
    'meaning',
    'lemma',
    'part of speech',
    'grammar',
    'example',
    'example translation',
    'notes',
    'tags',
  ];

  static const _bom = '﻿';
  static const _separator = '; ';

  /// The CSV text (without BOM). [tagsByEntry] maps entry ids to tag names.
  static String toCsv(
    List<VocabularyEntry> entries, {
    Map<String, List<String>> tagsByEntry = const {},
  }) {
    final buffer = StringBuffer()..write(_row(headers));
    for (final e in entries) {
      buffer.write(
        _row([
          e.original,
          e.meanings.map((m) => m.text).join(_separator),
          e.lemma ?? '',
          e.partOfSpeech ?? '',
          e.grammarInfo ?? '',
          e.exampleSentence ?? '',
          e.exampleTranslation ?? '',
          e.notes ?? '',
          (tagsByEntry[e.id] ?? const []).join(_separator),
        ]),
      );
    }
    return buffer.toString();
  }

  /// UTF-8 bytes with BOM.
  static Uint8List toBytes(
    List<VocabularyEntry> entries, {
    Map<String, List<String>> tagsByEntry = const {},
  }) => Uint8List.fromList(
    utf8.encode(_bom + toCsv(entries, tagsByEntry: tagsByEntry)),
  );

  static String _row(List<String> cells) => '${cells.map(_cell).join(',')}\r\n';

  /// Quotes a cell when it contains a comma, quote, line break or edge
  /// whitespace; quotes inside are doubled.
  static String _cell(String value) {
    final needsQuotes =
        value.contains(RegExp('[",\r\n]')) || value.trim() != value;
    return needsQuotes ? '"${value.replaceAll('"', '""')}"' : value;
  }
}
