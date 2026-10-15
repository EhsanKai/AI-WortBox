import 'package:drift/drift.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/id/id_generator.dart';
import '../../../core/language/language.dart';
import '../../../core/text/text_normalizer.dart';
import '../../../core/time/clock.dart';
import '../../../data/database/app_database.dart';
import '../domain/deck.dart';
import '../domain/deck_repository.dart';

class DriftDeckRepository implements DeckRepository {
  DriftDeckRepository(this._db, {required this._clock, required this._ids});

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Stream<List<DeckSummary>> watchDeckSummaries() {
    final entryCount = _db.vocabularyEntries.id.count();
    final query =
        _db.select(_db.decks).join([
            leftOuterJoin(
              _db.vocabularyEntries,
              _db.vocabularyEntries.deckId.equalsExp(_db.decks.id),
              useColumns: false,
            ),
          ])
          ..addColumns([entryCount])
          ..groupBy([_db.decks.id])
          ..orderBy([
            OrderingTerm.desc(_db.decks.createdAt),
            OrderingTerm.asc(_db.decks.id),
          ]);

    return query.watch().map(
      (rows) => [
        for (final row in rows)
          DeckSummary(
            deck: _toDomain(row.readTable(_db.decks)),
            entryCount: row.read(entryCount) ?? 0,
          ),
      ],
    );
  }

  @override
  Stream<Deck?> watchDeck(String id) => (_db.select(
    _db.decks,
  )..where((d) => d.id.equals(id))).watchSingleOrNull().map(_toDomainOrNull);

  @override
  Future<List<Deck>> getDecks() => _guard('getDecks', () async {
    final rows =
        await (_db.select(_db.decks)..orderBy([
              (d) => OrderingTerm.desc(d.createdAt),
              (d) => OrderingTerm.asc(d.id),
            ]))
            .get();
    return rows.map(_toDomain).toList();
  });

  @override
  Future<Deck?> getDeck(String id) => _guard('getDeck', () async {
    final row = await (_db.select(
      _db.decks,
    )..where((d) => d.id.equals(id))).getSingleOrNull();
    return _toDomainOrNull(row);
  });

  @override
  Future<Deck> createDeck(DeckDraft draft) async {
    final errors = draft.validate();
    if (errors.isNotEmpty) throw DeckValidationException(errors);

    final name = draft.cleanedName;
    return _guard('createDeck', () {
      return _db.transaction(() async {
        // Case-insensitive uniqueness is checked in Dart because SQLite's
        // lower()/NOCASE only fold ASCII letters (not Ä/Ö/Ü or Persian).
        final key = TextNormalizer.nameKey(name);
        final nameColumn = _db.decks.name;
        final existingNames = await (_db.selectOnly(
          _db.decks,
        )..addColumns([nameColumn])).map((row) => row.read(nameColumn)!).get();
        if (existingNames.any((n) => TextNormalizer.nameKey(n) == key)) {
          throw const DeckValidationException({
            DeckValidationError.nameDuplicate,
          });
        }

        final now = _clock.nowUtc();
        final companion = DecksCompanion.insert(
          id: _ids.newId(),
          name: name,
          sourceLanguage: draft.sourceLanguage.code,
          definitionLanguage: draft.definitionLanguage.code,
          dailyNewCardLimit: draft.dailyNewCardLimit,
          createdAt: now,
          updatedAt: now,
        );
        final row = await _db.into(_db.decks).insertReturning(companion);
        return _toDomain(row);
      });
    });
  }

  Deck? _toDomainOrNull(DeckRow? row) => row == null ? null : _toDomain(row);

  Deck _toDomain(DeckRow row) => Deck(
    id: row.id,
    name: row.name,
    sourceLanguage: Language.fromCode(row.sourceLanguage),
    definitionLanguage: Language.fromCode(row.definitionLanguage),
    dailyNewCardLimit: row.dailyNewCardLimit,
    createdAt: row.createdAt.toUtc(),
    updatedAt: row.updatedAt.toUtc(),
  );

  /// Lets [AppException]s through and wraps any other failure in a
  /// [StorageException].
  Future<T> _guard<T>(String operation, Future<T> Function() body) async {
    try {
      return await body();
    } on AppException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw StorageException(operation, error, stackTrace);
    }
  }
}
