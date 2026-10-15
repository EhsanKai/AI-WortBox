import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  final now = DateTime.utc(2026, 10, 15, 10);

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  Future<void> insertDeck([String id = 'deck-1']) => db
      .into(db.decks)
      .insert(
        DecksCompanion.insert(
          id: id,
          name: 'Deck $id',
          sourceLanguage: 'de',
          definitionLanguage: 'fa',
          dailyNewCardLimit: 20,
          createdAt: now,
          updatedAt: now,
        ),
      );

  Future<void> insertEntry({String id = 'entry-1', String deckId = 'deck-1'}) =>
      db
          .into(db.vocabularyEntries)
          .insert(
            VocabularyEntriesCompanion.insert(
              id: id,
              deckId: deckId,
              original: 'sich Mühe geben',
              normalized: 'sich mühe geben',
              sourceLanguage: 'de',
              definitionLanguage: 'fa',
              sourceType: VocabularySourceType.manual,
              enrichmentStatus: EnrichmentStatus.missing,
              createdAt: now,
              updatedAt: now,
            ),
          );

  Future<void> insertCard({
    String id = 'card-1',
    String entryId = 'entry-1',
    CardDirection direction = CardDirection.forward,
  }) => db
      .into(db.flashcards)
      .insert(
        FlashcardsCompanion.insert(
          id: id,
          entryId: entryId,
          direction: direction,
          state: CardState.newCard,
          due: now,
          createdAt: now,
          updatedAt: now,
        ),
      );

  test('creates schema version 1 with all tables', () async {
    expect(db.schemaVersion, 1);
    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%' ORDER BY name",
        )
        .map((row) => row.read<String>('name'))
        .get();
    expect(tables, [
      'decks',
      'flashcards',
      'vocabulary_entries',
      'vocabulary_meanings',
    ]);
  });

  test('enables foreign keys', () async {
    final row = await db.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.read<int>('foreign_keys'), 1);
  });

  test('rejects entries for a non-existent deck', () async {
    await expectLater(
      insertEntry(deckId: 'missing'),
      throwsA(isA<Exception>()),
    );
  });

  test('enforces the daily limit check constraint', () async {
    await expectLater(
      db
          .into(db.decks)
          .insert(
            DecksCompanion.insert(
              id: 'bad',
              name: 'Bad',
              sourceLanguage: 'de',
              definitionLanguage: 'fa',
              dailyNewCardLimit: 5000,
              createdAt: now,
              updatedAt: now,
            ),
          ),
      throwsA(isA<Exception>()),
    );
  });

  test(
    'stores Persian Unicode meanings in order and round-trips them',
    () async {
      await insertDeck();
      await insertEntry();
      const meanings = ['زحمت کشیدن', 'تلاش کردن', 'سعیِ خود را کردن'];
      for (var i = meanings.length - 1; i >= 0; i--) {
        await db
            .into(db.vocabularyMeanings)
            .insert(
              VocabularyMeaningsCompanion.insert(
                id: 'm$i',
                entryId: 'entry-1',
                position: i,
                meaning: meanings[i],
              ),
            );
      }
      final rows = await (db.select(
        db.vocabularyMeanings,
      )..orderBy([(m) => OrderingTerm.asc(m.position)])).get();
      expect(rows.map((r) => r.meaning), meanings);
    },
  );

  test('meaning positions are unique per entry', () async {
    await insertDeck();
    await insertEntry();
    final first = VocabularyMeaningsCompanion.insert(
      id: 'm1',
      entryId: 'entry-1',
      position: 0,
      meaning: 'الف',
    );
    await db.into(db.vocabularyMeanings).insert(first);
    await expectLater(
      db
          .into(db.vocabularyMeanings)
          .insert(first.copyWith(id: const Value('m2'))),
      throwsA(isA<Exception>()),
    );
  });

  test('allows one card per entry and direction', () async {
    await insertDeck();
    await insertEntry();
    await insertCard();
    await insertCard(id: 'card-2', direction: CardDirection.reverse);
    await expectLater(insertCard(id: 'card-3'), throwsA(isA<Exception>()));
  });

  test('editing vocabulary content does not touch review state', () async {
    await insertDeck();
    await insertEntry();
    await insertCard();
    await (db.update(db.flashcards)..where((c) => c.id.equals('card-1'))).write(
      FlashcardsCompanion(
        state: const Value(CardState.review),
        stability: const Value(12.5),
        difficulty: const Value(4.2),
        reviewCount: const Value(7),
        lapseCount: const Value(1),
        lastReviewedAt: Value(now),
      ),
    );
    final before = await db.select(db.flashcards).getSingle();

    await (db.update(
      db.vocabularyEntries,
    )..where((e) => e.id.equals('entry-1'))).write(
      VocabularyEntriesCompanion(
        notes: const Value('edited'),
        updatedAt: Value(now.add(const Duration(days: 1))),
      ),
    );

    expect(await db.select(db.flashcards).getSingle(), before);
  });

  test('deleting a deck cascades to entries, meanings and cards', () async {
    await insertDeck();
    await insertEntry();
    await db
        .into(db.vocabularyMeanings)
        .insert(
          VocabularyMeaningsCompanion.insert(
            id: 'm1',
            entryId: 'entry-1',
            position: 0,
            meaning: 'زحمت کشیدن',
          ),
        );
    await insertCard();

    await (db.delete(db.decks)..where((d) => d.id.equals('deck-1'))).go();

    expect(await db.select(db.vocabularyEntries).get(), isEmpty);
    expect(await db.select(db.vocabularyMeanings).get(), isEmpty);
    expect(await db.select(db.flashcards).get(), isEmpty);
  });

  test('stores timestamps as UTC ISO-8601 text', () async {
    await insertDeck();
    final raw = await db
        .customSelect('SELECT created_at FROM decks')
        .getSingle();
    expect(raw.read<String>('created_at'), '2026-10-15T10:00:00.000Z');
    final deck = await db.select(db.decks).getSingle();
    expect(deck.createdAt.isUtc, isTrue);
    expect(deck.createdAt, now);
  });
}
