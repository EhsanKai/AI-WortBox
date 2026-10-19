import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../csv_import/domain/csv_table.dart';
import '../domain/anki_html.dart';
import 'anki_sqlite.dart';

/// Reads the notes of an Anki package (`.apkg`, also `.colpkg`) into a
/// table for the import pipeline: one header row (the note fields, then
/// `tags`) and one record per note, as plain text.
///
/// Supported collection formats inside the ZIP, in order of preference:
/// - `collection.anki21b` — zstd-compressed SQLite, schema 18 (default of
///   Anki 2.1.50+ and 23.x–26.x);
/// - `collection.anki21` — SQLite, schema 11 ("support older Anki
///   versions" exports);
/// - `collection.anki2` — SQLite, schema 11 (old Anki, AnkiDroid, and
///   tools such as genanki). Newer packages also contain a placeholder
///   `collection.anki2` asking to update Anki; it is never imported.
///
/// Not imported: media files (images, audio), scheduling and review
/// history, deck structure (the user picks the target deck).
abstract final class AnkiPackageReader {
  /// ZIP local file header ("PK\x03\x04").
  static bool looksLikePackage(Uint8List bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x50 &&
      bytes[1] == 0x4B &&
      bytes[2] == 0x03 &&
      bytes[3] == 0x04;

  static const tagsHeader = 'tags';

  static CsvTable read(Uint8List bytes) {
    if (bytes.length > AppConfig.maxAnkiPackageBytes) {
      throw const AnkiImportException(AnkiImportError.tooLarge);
    }
    final Archive zip;
    try {
      zip = ZipDecoder().decodeBytes(bytes);
    } on Object {
      throw const AnkiImportException(AnkiImportError.notAnkiPackage);
    }
    ArchiveFile? entry(String name) => zip.findFile(name);

    final Uint8List collection;
    try {
      if (entry('collection.anki21b') case final f?) {
        collection = ZstdDecoder().decodeBytes(f.readBytes()!);
      } else if (entry('collection.anki21') case final f?) {
        collection = Uint8List.fromList(f.readBytes()!);
      } else if (entry('collection.anki2') case final f?) {
        collection = Uint8List.fromList(f.readBytes()!);
      } else {
        throw const AnkiImportException(AnkiImportError.notAnkiPackage);
      }
    } on AnkiImportException {
      rethrow;
    } on Object {
      throw const AnkiImportException(AnkiImportError.notAnkiPackage);
    }

    // Collections saved in WAL mode cannot be opened without their -wal
    // file; this private copy is switched to rollback mode (header bytes
    // 18–19), which only affects how SQLite opens it.
    if (collection.length > 100 && collection[18] == 2 && collection[19] == 2) {
      collection[18] = 1;
      collection[19] = 1;
    }

    final List<_Note> notes;
    try {
      (notes, _) = withMemoryDatabase(_readNotes, initial: collection);
    } on AnkiImportException {
      rethrow;
    } on Object {
      throw const AnkiImportException(AnkiImportError.unsupportedFormat);
    }
    if (notes.isEmpty) {
      throw const AnkiImportException(AnkiImportError.noNotes);
    }
    if (notes.length > AppConfig.maxCsvRows) {
      throw const CsvFormatException(CsvFormatError.tooManyRows);
    }
    return _toTable(notes);
  }

  static List<_Note> _readNotes(Database db) {
    // Anki defines a case-insensitive "unicase" collation; schema-18
    // tables (e.g. `fields`) cannot be queried without it.
    db.createCollation(
      name: 'unicase',
      function: (a, b) =>
          (a ?? '').toLowerCase().compareTo((b ?? '').toLowerCase()),
    );
    final fieldNames = _fieldNames(db);
    final rows = db.select('SELECT mid, tags, flds FROM notes ORDER BY id');
    final notes = [
      for (final row in rows)
        _Note(
          fieldNames: fieldNames[row['mid'] as int] ?? const [],
          values: (row['flds'] as String).split('\u001f'),
          tags: (row['tags'] as String)
              .split(RegExp(r'\s+'))
              .where((t) => t.isNotEmpty)
              .toList(),
        ),
    ];
    // The placeholder collection in new packages has exactly this note.
    if (notes.length == 1 &&
        notes.single.values.join(' ').contains('Please update to the latest')) {
      throw const AnkiImportException(AnkiImportError.unsupportedFormat);
    }
    return notes;
  }

  /// Field names per note type id, in field order.
  static Map<int, List<String>> _fieldNames(Database db) {
    final hasFieldsTable = db
        .select(
          "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'fields'",
        )
        .isNotEmpty;
    if (hasFieldsTable) {
      // Schema 18.
      final result = <int, List<String>>{};
      for (final row in db.select(
        'SELECT ntid, name FROM fields ORDER BY ntid, ord',
      )) {
        (result[row['ntid'] as int] ??= []).add(row['name'] as String);
      }
      return result;
    }
    // Schema 11: note types are JSON in col.models.
    final models = jsonDecode(
      db.select('SELECT models FROM col').first['models'] as String,
    ) as Map<String, dynamic>;
    return {
      for (final model in models.values.cast<Map<String, dynamic>>())
        (model['id'] as num).toInt(): [
          for (final field
              in (model['flds'] as List).cast<Map<String, dynamic>>()
                ..sort((a, b) => (a['ord'] as int).compareTo(b['ord'] as int)))
            field['name'] as String,
        ],
    };
  }

  /// Columns are the union of field names in first-seen order (matched by
  /// name, case-insensitively), then `tags`.
  static CsvTable _toTable(List<_Note> notes) {
    final columns = <String>[];
    final index = <String, int>{};
    for (final note in notes) {
      for (final name in note.fieldNames) {
        index.putIfAbsent(name.toLowerCase(), () {
          columns.add(name);
          return columns.length - 1;
        });
      }
    }
    final width = columns.length + 1;
    final records = <CsvRecord>[
      CsvRecord(line: 1, cells: [...columns, tagsHeader]),
    ];
    for (final (i, note) in notes.indexed) {
      final cells = List.filled(width, '');
      for (final (f, value) in note.values.indexed) {
        // Fields without a known name (damaged note type) are dropped.
        if (f >= note.fieldNames.length) continue;
        cells[index[note.fieldNames[f].toLowerCase()]!] = AnkiHtml.toText(
          value,
        );
      }
      cells[width - 1] = note.tags.join('; ');
      records.add(CsvRecord(line: i + 2, cells: cells));
    }
    return CsvTable(
      records: records,
      delimiter: '\t',
      encoding: CsvTextEncoding.utf8,
      delimiterWasDetected: false,
      source: CsvTableSource.ankiPackage,
    );
  }
}

class _Note {
  const _Note({
    required this.fieldNames,
    required this.values,
    required this.tags,
  });

  final List<String> fieldNames;
  final List<String> values;
  final List<String> tags;
}
