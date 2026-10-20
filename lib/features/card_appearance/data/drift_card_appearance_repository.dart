import 'package:drift/drift.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/time/clock.dart';
import '../../../data/database/app_database.dart';
import '../domain/card_appearance.dart';

/// Card appearances in `card_appearances` (schema v4). Touches no other
/// table.
class DriftCardAppearanceRepository implements CardAppearanceRepository {
  DriftCardAppearanceRepository(this._db, {required this._clock});

  final AppDatabase _db;
  final Clock _clock;

  $CardAppearancesTable get _table => _db.cardAppearances;

  SimpleSelectStatement<$CardAppearancesTable, CardAppearanceRow> _row(
    String entryId,
  ) => _db.select(_table)..where((t) => t.entryId.equals(entryId));

  @override
  Stream<CardAppearance> watch(String entryId) =>
      _row(entryId).watchSingleOrNull().map(fromRow);

  @override
  Future<CardAppearance> get(String entryId) =>
      _guard('cardAppearance.get', () async {
        return fromRow(await _row(entryId).getSingleOrNull());
      });

  @override
  Future<void> save(
    String entryId,
    CardAppearance appearance,
  ) => _guard('cardAppearance.save', () async {
    if (appearance.isStandard) {
      await (_db.delete(_table)..where((t) => t.entryId.equals(entryId))).go();
      return;
    }
    await _db.into(_table).insertOnConflictUpdate(toRow(entryId, appearance));
  });

  CardAppearancesCompanion toRow(String entryId, CardAppearance a) =>
      CardAppearancesCompanion.insert(
        entryId: entryId,
        background: Value(
          a.background == CardColor.standard ? null : a.background.name,
        ),
        ink: Value(a.ink == CardInk.standard ? null : a.ink.name),
        wordScale: Value(a.wordScale),
        meaningScale: Value(a.meaningScale),
        highlightColor: Value(a.highlightColor.name),
        highlights: Value(a.highlightsJson),
        sticker: Value(a.sticker?.name),
        updatedAt: _clock.nowUtc(),
      );

  /// The appearance stored in [row]; the standard one for no row. Unknown
  /// or out-of-range values read as the default.
  static CardAppearance fromRow(CardAppearanceRow? row) {
    if (row == null) return CardAppearance.standard;
    return CardAppearance(
      background: CardAppearance.byName(
        CardColor.values,
        row.background,
        CardColor.standard,
      ),
      ink: CardAppearance.byName(CardInk.values, row.ink, CardInk.standard),
      wordScale: CardAppearance.clampScale(row.wordScale),
      meaningScale: CardAppearance.clampScale(row.meaningScale),
      highlightColor: CardAppearance.byName(
        HighlightColor.values,
        row.highlightColor,
        HighlightColor.yellow,
      ),
      highlights: CardAppearance.parseHighlights(row.highlights),
      sticker: CardSticker.values
          .where((s) => s.name == row.sticker)
          .firstOrNull,
    );
  }

  Future<T> _guard<T>(String operation, Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      throw StorageException(operation, error, stackTrace);
    }
  }
}
