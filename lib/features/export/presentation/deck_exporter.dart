import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/error/app_exception.dart';
import '../../anki/data/anki_package_writer.dart';
import '../../decks/domain/deck.dart';
import '../domain/csv_exporter.dart';
import '../domain/export_file_sink.dart';

enum ExportFormat { csv, ankiPackage }

/// Exports one deck and lets the user save the file.
class DeckExporter {
  DeckExporter(this._ref);

  final Ref _ref;

  /// Returns false when the user cancelled the save dialog. Throws
  /// [ExportException] for an empty deck or a failed write.
  Future<bool> export(Deck deck, ExportFormat format) async {
    final entries = await _ref
        .read(vocabularyRepositoryProvider)
        .getEntries(deck.id);
    if (entries.isEmpty) throw const ExportException(ExportError.empty);
    // Oldest first, like the order the words were added.
    final ordered = entries.reversed.toList();
    final tags = await _ref
        .read(tagRepositoryProvider)
        .getTagNamesForDeck(deck.id);
    final clock = _ref.read(clockProvider);
    final now = clock.nowUtc();
    final localDate = clock.toLocal(now);
    final sink = _ref.read(exportFileSinkProvider);
    return switch (format) {
      ExportFormat.csv => sink.save(
        fileName: exportFileName(deck.name, localDate, 'csv'),
        bytes: CsvExporter.toBytes(ordered, tagsByEntry: tags),
        mimeType: 'text/csv',
      ),
      ExportFormat.ankiPackage => sink.save(
        fileName: exportFileName(deck.name, localDate, 'apkg'),
        bytes: AnkiPackageWriter.build(
          deckName: deck.name,
          entries: ordered,
          tagsByEntry: tags,
          nowUtc: now,
        ),
        mimeType: 'application/octet-stream',
      ),
    };
  }
}

final deckExporterProvider = Provider<DeckExporter>(DeckExporter.new);
