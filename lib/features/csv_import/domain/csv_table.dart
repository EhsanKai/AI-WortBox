import 'package:flutter/foundation.dart';

/// Text encoding a CSV file was read with.
enum CsvTextEncoding { utf8, utf8Bom, utf16le, utf16be }

/// One logical CSV record. [line] is the 1-based physical line on which the
/// record starts (records may span lines inside quoted fields).
@immutable
class CsvRecord {
  const CsvRecord({required this.line, required this.cells});

  final int line;
  final List<String> cells;

  /// The cell at [index], or an empty string for short rows.
  String cell(int index) => index < cells.length ? cells[index] : '';

  @override
  bool operator ==(Object other) =>
      other is CsvRecord &&
      other.line == line &&
      listEquals(other.cells, cells);

  @override
  int get hashCode => Object.hash(line, Object.hashAll(cells));

  @override
  String toString() => 'CsvRecord(line $line: $cells)';
}

/// A decoded and parsed CSV file. Blank lines are not included.
@immutable
class CsvTable {
  const CsvTable({
    required this.records,
    required this.delimiter,
    required this.encoding,
    required this.delimiterWasDetected,
  });

  final List<CsvRecord> records;
  final String delimiter;
  final CsvTextEncoding encoding;

  /// False when the delimiter was chosen by the user or by a `sep=` line.
  final bool delimiterWasDetected;

  /// Number of columns of the widest record.
  int get columnCount =>
      records.fold(0, (max, r) => r.cells.length > max ? r.cells.length : max);
}
