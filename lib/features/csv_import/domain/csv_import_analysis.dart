import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/text/script_detector.dart';
import '../../vocabulary/domain/duplicate_detection.dart';
import '../../vocabulary/domain/vocabulary_draft.dart';
import '../../vocabulary/domain/vocabulary_entry.dart';
import 'column_mapping.dart';
import 'csv_table.dart';

/// A problem that prevents one row from being imported. Other rows are not
/// affected.
enum ImportRowIssue {
  missingWord,
  wordTooLong,
  meaningTooLong,
  tooManyMeanings,
  fieldTooLong,
}

/// The interpretation of one CSV data row.
@immutable
class ImportRow {
  const ImportRow({
    required this.rowNumber,
    required this.line,
    required this.draft,
    required this.issues,
  });

  /// 1-based index among data rows (the header is not counted).
  final int rowNumber;

  /// 1-based physical line in the file, as shown by text editors and
  /// spreadsheet apps (when no cell contains a line break).
  final int line;

  /// Cleaned draft built from the row (also present for invalid rows, for
  /// display).
  final VocabularyDraft draft;

  final Set<ImportRowIssue> issues;

  bool get isValid => issues.isEmpty;
}

/// Everything the preview screen shows, and the input for the import.
@immutable
class CsvImportAnalysis {
  const CsvImportAnalysis({
    required this.rows,
    required this.decisions,
    required this.languagesLookSwapped,
  });

  /// Non-blank data rows in file order.
  final List<ImportRow> rows;

  /// Decisions for valid rows, keyed by [ImportRow.rowNumber].
  final Map<int, ImportDecision> decisions;

  /// The word column looks Persian and a meaning column looks Latin.
  final bool languagesLookSwapped;

  List<ImportRow> get invalidRows => rows.where((r) => !r.isValid).toList();

  List<ImportCandidate> get candidates => [
    for (final row in rows)
      if (row.isValid)
        ImportCandidate(rowNumber: row.rowNumber, draft: row.draft),
  ];

  int get createCount => decisions.values.whereType<CreateDecision>().length;

  int get mergeCount => decisions.values
      .where((d) => d is MergeIntoEntryDecision || d is MergeIntoRowDecision)
      .length;

  int get skipCount => decisions.values.whereType<SkipDecision>().length;

  int get errorCount => invalidRows.length;

  /// Rows that will change the database.
  int get actionableCount => createCount + mergeCount;
}

/// Characters that separate several meanings inside one cell.
final _meaningSeparators = RegExp(r'[;؛|\n]');

/// Splits a meaning cell like "خانه؛ منزل" into separate meanings. Commas are
/// not separators because they occur inside Persian and German phrases.
List<String> splitMeanings(String cell) => cell
    .split(_meaningSeparators)
    .map((m) => m.trim())
    .where((m) => m.isNotEmpty)
    .toList();

/// Interprets [table] with [mapping] and plans the import against the deck's
/// [existing] entries. Pure and deterministic.
CsvImportAnalysis analyzeCsvImport({
  required CsvTable table,
  required ColumnMapping mapping,
  required String deckId,
  required List<VocabularyEntry> existing,
  required DuplicateStrategy strategy,
}) {
  final dataRecords = mapping.hasHeader ? table.records.skip(1) : table.records;

  final rows = <ImportRow>[];
  var rowNumber = 0;
  for (final record in dataRecords) {
    rowNumber++;
    final draft = _draftFrom(record, mapping, deckId);
    if (draft == null) continue; // Every mapped cell is blank.
    rows.add(
      ImportRow(
        rowNumber: rowNumber,
        line: record.line,
        draft: draft,
        issues: _issuesOf(draft),
      ),
    );
  }

  final analysisRows = List<ImportRow>.unmodifiable(rows);
  final candidates = [
    for (final row in analysisRows)
      if (row.isValid)
        ImportCandidate(rowNumber: row.rowNumber, draft: row.draft),
  ];
  final decisions = planImport(candidates, existing, strategy);

  return CsvImportAnalysis(
    rows: analysisRows,
    decisions: {for (final d in decisions) d.rowNumber: d},
    languagesLookSwapped: _looksSwapped(analysisRows),
  );
}

VocabularyDraft? _draftFrom(
  CsvRecord record,
  ColumnMapping mapping,
  String deckId,
) {
  String? single(ImportField field) {
    final index = mapping.fields.indexOf(field);
    if (index < 0) return null;
    final value = record.cell(index).trim();
    return value.isEmpty ? null : value;
  }

  final meanings = <VocabularyMeaning>[];
  for (var i = 0; i < mapping.fields.length; i++) {
    if (mapping.fields[i] != ImportField.meaning) continue;
    meanings.addAll(splitMeanings(record.cell(i)).map(VocabularyMeaning.new));
  }

  final original = single(ImportField.original);
  final draft = VocabularyDraft(
    deckId: deckId,
    original: original ?? '',
    meanings: meanings,
    lemma: single(ImportField.lemma),
    partOfSpeech: single(ImportField.partOfSpeech),
    exampleSentence: single(ImportField.exampleSentence),
    exampleTranslation: single(ImportField.exampleTranslation),
    grammarInfo: single(ImportField.grammarInfo),
    notes: single(ImportField.notes),
    sourceType: VocabularySourceType.csv,
  ).cleaned();

  final isBlank =
      draft.original.isEmpty &&
      draft.meanings.isEmpty &&
      draft.lemma == null &&
      draft.partOfSpeech == null &&
      draft.exampleSentence == null &&
      draft.exampleTranslation == null &&
      draft.grammarInfo == null &&
      draft.notes == null;
  return isBlank ? null : draft;
}

Set<ImportRowIssue> _issuesOf(VocabularyDraft draft) => {
  for (final error in draft.validate())
    switch (error) {
      VocabularyValidationError.originalEmpty => ImportRowIssue.missingWord,
      VocabularyValidationError.originalTooLong => ImportRowIssue.wordTooLong,
      VocabularyValidationError.meaningTooLong => ImportRowIssue.meaningTooLong,
      VocabularyValidationError.tooManyMeanings =>
        ImportRowIssue.tooManyMeanings,
      VocabularyValidationError.fieldTooLong ||
      VocabularyValidationError.deckNotFound => ImportRowIssue.fieldTooLong,
    },
};

bool _looksSwapped(List<ImportRow> rows) {
  final sample = rows.take(30).toList();
  if (sample.isEmpty) return false;
  final words = sample.map((r) => r.draft.original).where((w) => w.isNotEmpty);
  final meanings = sample.expand((r) => r.draft.meanings.map((m) => m.text));
  bool mostly(Iterable<String> values, bool Function(String) test) {
    final list = values.toList();
    return list.isNotEmpty && list.where(test).length * 2 > list.length;
  }

  return mostly(words, ScriptDetector.isMostlyRtl) &&
      (meanings.isEmpty || mostly(meanings, ScriptDetector.isMostlyLatin));
}
