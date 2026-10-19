import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/error/app_exception.dart';
import '../../anki/data/anki_package_reader.dart';
import '../../vocabulary/domain/duplicate_detection.dart';
import '../../vocabulary/domain/vocabulary_repository.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
import '../data/csv_file_source.dart';
import '../data/csv_parser.dart';
import '../domain/column_mapping.dart';
import '../domain/csv_import_analysis.dart';
import '../domain/csv_table.dart';

/// State of the CSV import flow. Nothing is written to the database until
/// [CsvImportController.runImport].
@immutable
class CsvImportState {
  const CsvImportState({
    this.deckId,
    this.file,
    this.table,
    this.delimiterOverride,
    this.mapping,
    this.strategy = DuplicateStrategy.skip,
    this.languagesConfirmed = false,
    this.fileError,
    this.isLoadingFile = false,
    this.isImporting = false,
    this.result,
    this.resultErrorCount = 0,
    this.importError,
  });

  final String? deckId;
  final PickedCsvFile? file;
  final CsvTable? table;

  /// Delimiter chosen by the user; null means automatic.
  final String? delimiterOverride;
  final ColumnMapping? mapping;
  final DuplicateStrategy strategy;
  final bool languagesConfirmed;

  /// Fatal problem with the selected file.
  final Object? fileError;
  final bool isLoadingFile;
  final bool isImporting;
  final ImportSummary? result;

  /// Rows that were not imported because of row-level errors.
  final int resultErrorCount;
  final Object? importError;

  CsvImportState copyWith({
    String? deckId,
    PickedCsvFile? file,
    CsvTable? table,
    ColumnMapping? mapping,
    DuplicateStrategy? strategy,
    bool? languagesConfirmed,
    bool? isLoadingFile,
    bool? isImporting,
  }) => CsvImportState(
    deckId: deckId ?? this.deckId,
    file: file ?? this.file,
    table: table ?? this.table,
    delimiterOverride: delimiterOverride,
    mapping: mapping ?? this.mapping,
    strategy: strategy ?? this.strategy,
    languagesConfirmed: languagesConfirmed ?? this.languagesConfirmed,
    fileError: fileError,
    isLoadingFile: isLoadingFile ?? this.isLoadingFile,
    isImporting: isImporting ?? this.isImporting,
    result: result,
    resultErrorCount: resultErrorCount,
    // A previous import error is cleared by any change.
  );
}

/// Files above this size are parsed on a background isolate.
const _backgroundParseThreshold = 256 * 1024;

class CsvImportController extends Notifier<CsvImportState> {
  CsvImportController(this.initialDeckId);

  final String? initialDeckId;

  @override
  CsvImportState build() => CsvImportState(deckId: initialDeckId);

  void selectDeck(String deckId) => state = state.copyWith(deckId: deckId);

  Future<void> pickFile() async {
    state = state.copyWith(isLoadingFile: true);
    try {
      final file = await ref.read(csvFileSourceProvider).pick();
      if (file == null) {
        state = state.copyWith(isLoadingFile: false);
        return;
      }
      await loadFile(file);
    } on AppException catch (e) {
      state = _withFileError(e);
    } on Object catch (e) {
      // Platform errors from the picker (e.g. unreadable cloud file).
      state = _withFileError(e);
    }
  }

  /// Parses [file] and suggests a column mapping.
  Future<void> loadFile(PickedCsvFile file) async {
    state = CsvImportState(
      deckId: state.deckId,
      file: file,
      strategy: state.strategy,
      isLoadingFile: true,
    );
    await _parse(file, delimiter: null);
  }

  /// Re-parses the current file with [delimiter] (null = automatic).
  Future<void> setDelimiter(String? delimiter) async {
    final file = state.file;
    if (file == null) return;
    state = CsvImportState(
      deckId: state.deckId,
      file: file,
      delimiterOverride: delimiter,
      strategy: state.strategy,
      isLoadingFile: true,
    );
    await _parse(file, delimiter: delimiter);
  }

  Future<void> _parse(PickedCsvFile file, {required String? delimiter}) async {
    try {
      final table = await _read(file.bytes, delimiter);
      state = CsvImportState(
        deckId: state.deckId,
        file: file,
        table: table,
        delimiterOverride: delimiter,
        mapping: HeaderRecognizer.suggest(table),
        strategy: state.strategy,
      );
    } on AppException catch (e) {
      state = _withFileError(e);
    }
  }

  /// CSV/TSV text, or an Anki package (recognized by its ZIP signature,
  /// whatever the file name).
  static Future<CsvTable> _read(Uint8List bytes, String? delimiter) {
    CsvTable parse() => AnkiPackageReader.looksLikePackage(bytes)
        ? AnkiPackageReader.read(bytes)
        : CsvParser.read(bytes, delimiter: delimiter);
    if (bytes.length < _backgroundParseThreshold) return Future.sync(parse);
    return Isolate.run(parse);
  }

  void setHasHeader(bool value) {
    final mapping = state.mapping;
    if (mapping == null) return;
    state = state.copyWith(mapping: mapping.withHeader(value));
  }

  void setField(int column, ImportField field) {
    final mapping = state.mapping;
    if (mapping == null) return;
    state = state.copyWith(mapping: mapping.withField(column, field));
  }

  void swapLanguageColumns() {
    final mapping = state.mapping;
    if (mapping == null) return;
    state = state.copyWith(mapping: mapping.swapOriginalAndMeaning());
  }

  void setStrategy(DuplicateStrategy strategy) =>
      state = state.copyWith(strategy: strategy);

  void setLanguagesConfirmed(bool value) =>
      state = state.copyWith(languagesConfirmed: value);

  /// Writes [analysis] to the database in one transaction.
  Future<void> runImport(CsvImportAnalysis analysis) async {
    final deckId = state.deckId;
    if (deckId == null || state.isImporting) return;
    state = state.copyWith(isImporting: true);
    try {
      final summary = await ref
          .read(vocabularyRepositoryProvider)
          .importEntries(deckId, analysis.candidates, state.strategy);
      state = CsvImportState(
        deckId: deckId,
        strategy: state.strategy,
        result: summary,
        resultErrorCount: analysis.errorCount,
      );
    } on AppException catch (e) {
      state = CsvImportState(
        deckId: state.deckId,
        file: state.file,
        table: state.table,
        delimiterOverride: state.delimiterOverride,
        mapping: state.mapping,
        strategy: state.strategy,
        languagesConfirmed: state.languagesConfirmed,
        importError: e,
      );
    }
  }

  /// Starts over with another file, keeping the deck and strategy.
  void reset() =>
      state = CsvImportState(deckId: state.deckId, strategy: state.strategy);

  CsvImportState _withFileError(Object error) => CsvImportState(
    deckId: state.deckId,
    strategy: state.strategy,
    fileError: error,
  );
}

final csvImportControllerProvider = NotifierProvider.autoDispose
    .family<CsvImportController, CsvImportState, String?>(
      CsvImportController.new,
    );

/// The preview for the current state, or null while input is incomplete.
final csvImportAnalysisProvider = Provider.autoDispose
    .family<AsyncValue<CsvImportAnalysis?>, String?>((ref, initialDeckId) {
      final (table, mapping, deckId, strategy) = ref.watch(
        csvImportControllerProvider(initialDeckId)
            .select((s) => (s.table, s.mapping, s.deckId, s.strategy)),
      );
      if (table == null || mapping == null || deckId == null) {
        return const AsyncData(null);
      }
      if (!mapping.hasOriginal) return const AsyncData(null);
      return ref
          .watch(deckEntriesProvider(deckId))
          .whenData(
            (existing) => analyzeCsvImport(
              table: table,
              mapping: mapping,
              deckId: deckId,
              existing: existing,
              strategy: strategy,
            ),
          );
    });
