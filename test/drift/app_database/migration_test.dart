// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/review/data/drift_study_repository.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/review/domain/review_event.dart';
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;
import 'generated/schema_v3.dart' as v3;
import 'generated/schema_v4.dart' as v4;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // Every schema step on an empty database must produce exactly the
    // exported schema of the target version.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('v1 → v2 keeps every deck, entry, meaning and flashcard unchanged '
      'and backfills search keys', () async {
    const created = '2026-10-15T08:00:00.000Z';
    const edited = '2026-10-15T09:30:00.000Z';
    final decks = [
      const v1.DecksData(
        id: 'deck-1',
        name: 'Kafka — Die Verwandlung',
        sourceLanguage: 'de',
        definitionLanguage: 'fa',
        dailyNewCardLimit: 20,
        createdAt: created,
        updatedAt: created,
      ),
    ];
    final entries = [
      const v1.VocabularyEntriesData(
        id: 'e-1',
        deckId: 'deck-1',
        original: 'Ungeziefer',
        normalized: 'ungeziefer',
        sourceLanguage: 'de',
        definitionLanguage: 'fa',
        grammarInfo: 'das Ungeziefer, -s, kein Plural',
        sourceContext: 'zu einem ungeheueren Ungeziefer verwandelt.',
        sourceType: 'image',
        enrichmentStatus: 'ready',
        enrichmentMetadata:
            '{"provider":"openrouter","model":"m","generatedAt":"$created",'
            '"isAmbiguous":false}',
        userEditedAt: edited,
        createdAt: created,
        updatedAt: edited,
      ),
      const v1.VocabularyEntriesData(
        id: 'e-2',
        deckId: 'deck-1',
        original: 'ging',
        normalized: 'ging',
        lemma: 'Gehen',
        sourceLanguage: 'de',
        definitionLanguage: 'fa',
        sourceType: 'csv',
        enrichmentStatus: 'missing',
        createdAt: created,
        updatedAt: created,
      ),
    ];
    final meanings = [
      const v1.VocabularyMeaningsData(
        id: 'm-1',
        entryId: 'e-1',
        position: 0,
        // Arabic YEH and a ZWNJ, stored as typed.
        meaning: 'حشره‌ی موذي',
        explanation: 'در معنای تحقیرآمیز',
      ),
      const v1.VocabularyMeaningsData(
        id: 'm-2',
        entryId: 'e-1',
        position: 1,
        meaning: 'جانور',
      ),
    ];
    final cards = [
      const v1.FlashcardsData(
        id: 'c-1',
        entryId: 'e-1',
        direction: 'forward',
        state: 'review',
        step: null,
        stability: 3.5,
        difficulty: 5.1,
        due: '2026-10-20T08:00:00.000Z',
        lastReviewedAt: edited,
        reviewCount: 4,
        lapseCount: 1,
        schedulerVersion: 'test',
        createdAt: created,
        updatedAt: edited,
      ),
    ];

    v2.VocabularyEntriesData migrated(
      v1.VocabularyEntriesData e,
      String searchKey,
    ) => v2.VocabularyEntriesData(
      id: e.id,
      deckId: e.deckId,
      original: e.original,
      normalized: e.normalized,
      lemma: e.lemma,
      sourceLanguage: e.sourceLanguage,
      definitionLanguage: e.definitionLanguage,
      partOfSpeech: e.partOfSpeech,
      exampleSentence: e.exampleSentence,
      exampleTranslation: e.exampleTranslation,
      grammarInfo: e.grammarInfo,
      notes: e.notes,
      sourceContext: e.sourceContext,
      sourceType: e.sourceType,
      enrichmentStatus: e.enrichmentStatus,
      enrichmentMetadata: e.enrichmentMetadata,
      userEditedAt: e.userEditedAt,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      markedDifficultAt: null,
      searchKey: searchKey,
    );

    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.decks, decks);
        batch.insertAll(oldDb.vocabularyEntries, entries);
        batch.insertAll(oldDb.vocabularyMeanings, meanings);
        batch.insertAll(oldDb.flashcards, cards);
      },
      validateItems: (newDb) async {
        expect(
          (await newDb.select(newDb.decks).get()).map((d) => d.toJson()),
          decks.map((d) => d.toJson()),
        );
        expect(await newDb.select(newDb.vocabularyEntries).get(), [
          // Word, then meanings: Persian letters unified, diacritics and
          // ZWNJ ignored. The stored meaning text is unchanged (below).
          migrated(entries[0], 'ungeziefer\nحشرهی موذی\nجانور'),
          migrated(entries[1], 'ging\ngehen'),
        ]);
        expect(
          (await newDb.select(newDb.vocabularyMeanings).get()).map(
            (m) => m.toJson(),
          ),
          meanings.map((m) => m.toJson()),
        );
        expect(
          (await newDb.select(newDb.flashcards).get()).map((c) => c.toJson()),
          cards.map((c) => c.toJson()),
        );
        expect(await newDb.select(newDb.tags).get(), isEmpty);
        expect(await newDb.select(newDb.entryTags).get(), isEmpty);
        expect(await newDb.select(newDb.reviewEvents).get(), isEmpty);
        expect(await newDb.select(newDb.appSettings).get(), isEmpty);
      },
    );
  });

  test('v2 → v3 keeps every v2 row unchanged (decks, words, meanings, FSRS '
      'cards, tags, review history, settings) and adds an empty '
      'sentence-practice table', () async {
    const t = '2026-10-19T08:00:00.000Z';
    const later = '2026-10-19T09:00:00.000Z';
    final decks = [
      const v2.DecksData(
        id: 'deck-1',
        name: 'Kafka',
        sourceLanguage: 'de',
        definitionLanguage: 'fa',
        dailyNewCardLimit: 15,
        createdAt: t,
        updatedAt: t,
      ),
    ];
    final entries = [
      const v2.VocabularyEntriesData(
        id: 'e-1',
        deckId: 'deck-1',
        original: 'Ungeziefer',
        normalized: 'ungeziefer',
        sourceLanguage: 'de',
        definitionLanguage: 'fa',
        sourceType: 'image',
        enrichmentStatus: 'ready',
        createdAt: t,
        updatedAt: t,
        markedDifficultAt: later,
        searchKey: 'ungeziefer\nحشره',
      ),
    ];
    final meanings = [
      const v2.VocabularyMeaningsData(
        id: 'm-1',
        entryId: 'e-1',
        position: 0,
        meaning: 'حشره',
      ),
    ];
    final cards = [
      const v2.FlashcardsData(
        id: 'c-1',
        entryId: 'e-1',
        direction: 'forward',
        state: 'review',
        step: null,
        stability: 7.25,
        difficulty: 4.9,
        due: '2026-10-25T08:00:00.000Z',
        lastReviewedAt: later,
        reviewCount: 6,
        lapseCount: 2,
        schedulerVersion: 'fsrs-2.0.1;default;retention=0.9',
        createdAt: t,
        updatedAt: later,
      ),
    ];
    final tags = [
      const v2.TagsData(
        id: 't-1',
        name: 'B1',
        nameKey: 'b1',
        createdAt: t,
        updatedAt: t,
      ),
    ];
    final entryTags = [
      const v2.EntryTagsData(entryId: 'e-1', tagId: 't-1', createdAt: t),
    ];
    final events = [
      const v2.ReviewEventsData(
        id: 'r-1',
        entryId: 'e-1',
        sessionId: 's-1',
        direction: 'forward',
        outcome: 'remembered',
        reviewedAt: later,
        localDay: '2026-10-19',
      ),
      const v2.ReviewEventsData(
        id: 'r-2',
        entryId: null,
        sessionId: 's-1',
        direction: 'reverse',
        outcome: 'forgotten',
        reviewedAt: later,
        localDay: '2026-10-19',
      ),
    ];
    final settings = [
      const v2.AppSettingsData(key: 'review.direction', value: 'both'),
      const v2.AppSettingsData(key: 'ai.freeOnly', value: 'true'),
    ];

    List<Map<String, Object?>> json(Iterable<Insertable<Object>> rows) => [
      for (final r in rows)
        {
          for (final MapEntry(:key, :value) in r.toColumns(false).entries)
            key: (value as Variable).value,
        },
    ];

    await verifier.testWithDataIntegrity(
      oldVersion: 2,
      newVersion: 3,
      createOld: v2.DatabaseAtV2.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.decks, decks);
        batch.insertAll(oldDb.vocabularyEntries, entries);
        batch.insertAll(oldDb.vocabularyMeanings, meanings);
        batch.insertAll(oldDb.flashcards, cards);
        batch.insertAll(oldDb.tags, tags);
        batch.insertAll(oldDb.entryTags, entryTags);
        batch.insertAll(oldDb.reviewEvents, events);
        batch.insertAll(oldDb.appSettings, settings);
      },
      validateItems: (newDb) async {
        expect(json(await newDb.select(newDb.decks).get()), json(decks));
        expect(
          json(await newDb.select(newDb.vocabularyEntries).get()),
          json(entries),
        );
        expect(
          json(await newDb.select(newDb.vocabularyMeanings).get()),
          json(meanings),
        );
        expect(json(await newDb.select(newDb.flashcards).get()), json(cards));
        expect(json(await newDb.select(newDb.tags).get()), json(tags));
        expect(
          json(await newDb.select(newDb.entryTags).get()),
          json(entryTags),
        );
        expect(
          json(await newDb.select(newDb.reviewEvents).get()),
          json(events),
        );
        expect(
          json(await newDb.select(newDb.appSettings).get()),
          json(settings),
        );
        expect(await newDb.select(newDb.sentencePracticeEvents).get(), isEmpty);
      },
    );
  });

  test(
    'v3 → v4 keeps every v3 row unchanged (words, FSRS cards, review '
    'and sentence-practice history) and adds an empty appearance table',
    () async {
      const t = '2026-10-20T08:00:00.000Z';
      final decks = [
        const v3.DecksData(
          id: 'deck-1',
          name: 'Kafka',
          sourceLanguage: 'de',
          definitionLanguage: 'fa',
          dailyNewCardLimit: 20,
          createdAt: t,
          updatedAt: t,
        ),
      ];
      final entries = [
        const v3.VocabularyEntriesData(
          id: 'e-1',
          deckId: 'deck-1',
          original: 'Haus\nHäuser',
          normalized: 'haus häuser',
          sourceLanguage: 'de',
          definitionLanguage: 'fa',
          sourceType: 'manual',
          enrichmentStatus: 'ready',
          createdAt: t,
          updatedAt: t,
          searchKey: 'haus',
        ),
      ];
      final meanings = [
        const v3.VocabularyMeaningsData(
          id: 'm-1',
          entryId: 'e-1',
          position: 0,
          meaning: 'خانه‌ها',
        ),
      ];
      final cards = [
        const v3.FlashcardsData(
          id: 'c-1',
          entryId: 'e-1',
          direction: 'reverse',
          state: 'learning',
          step: 1,
          stability: 1.25,
          difficulty: 6.5,
          due: '2026-10-20T08:10:00.000Z',
          lastReviewedAt: t,
          reviewCount: 1,
          lapseCount: 0,
          schedulerVersion: 'fsrs-2.0.1;default;retention=0.9',
          createdAt: t,
          updatedAt: t,
        ),
      ];
      final events = [
        const v3.ReviewEventsData(
          id: 'r-1',
          entryId: 'e-1',
          sessionId: 's',
          direction: 'reverse',
          outcome: 'forgotten',
          reviewedAt: t,
          localDay: '2026-10-20',
        ),
      ];
      final practice = [
        const v3.SentencePracticeEventsData(
          id: 'p-1',
          entryId: 'e-1',
          direction: 'produce',
          level: 'b1',
          outcome: 'acceptable',
          practicedAt: t,
        ),
      ];

      List<Map<String, Object?>> json(Iterable<Insertable<Object>> rows) => [
        for (final r in rows)
          {
            for (final MapEntry(:key, :value) in r.toColumns(false).entries)
              key: (value as Variable).value,
          },
      ];

      await verifier.testWithDataIntegrity(
        oldVersion: 3,
        newVersion: 4,
        createOld: v3.DatabaseAtV3.new,
        createNew: v4.DatabaseAtV4.new,
        openTestedDatabase: AppDatabase.new,
        createItems: (batch, oldDb) {
          batch.insertAll(oldDb.decks, decks);
          batch.insertAll(oldDb.vocabularyEntries, entries);
          batch.insertAll(oldDb.vocabularyMeanings, meanings);
          batch.insertAll(oldDb.flashcards, cards);
          batch.insertAll(oldDb.reviewEvents, events);
          batch.insertAll(oldDb.sentencePracticeEvents, practice);
        },
        validateItems: (newDb) async {
          expect(json(await newDb.select(newDb.decks).get()), json(decks));
          expect(
            json(await newDb.select(newDb.vocabularyEntries).get()),
            json(entries),
          );
          expect(
            json(await newDb.select(newDb.vocabularyMeanings).get()),
            json(meanings),
          );
          expect(json(await newDb.select(newDb.flashcards).get()), json(cards));
          expect(
            json(await newDb.select(newDb.reviewEvents).get()),
            json(events),
          );
          expect(
            json(await newDb.select(newDb.sentencePracticeEvents).get()),
            json(practice),
          );
          expect(await newDb.select(newDb.cardAppearances).get(), isEmpty);
        },
      );
    },
  );

  test('FSRS review works on a database created before scheduling was '
      'active: old words become new cards, existing card rows are reused, '
      'nothing is lost', () async {
    final schema = await verifier.schemaAt(1);
    const t = '2026-10-15T08:00:00.000Z';
    schema.rawDatabase
      ..execute(
        "INSERT INTO decks VALUES ('deck-1', 'Kafka', 'de', 'fa', 20, '$t', '$t')",
      )
      ..execute(
        'INSERT INTO vocabulary_entries (id, deck_id, original, normalized, '
        'source_language, definition_language, source_type, '
        'enrichment_status, created_at, updated_at) VALUES '
        "('e-1', 'deck-1', 'Ungeziefer', 'ungeziefer', 'de', 'fa', 'image', "
        "'ready', '$t', '$t'), "
        "('e-2', 'deck-1', 'Käfer', 'käfer', 'de', 'fa', 'manual', "
        "'ready', '$t', '$t')",
      )
      ..execute(
        'INSERT INTO vocabulary_meanings VALUES '
        "('m-1', 'e-1', 0, 'حشره', NULL), ('m-2', 'e-2', 0, 'سوسک', NULL)",
      )
      ..execute(
        'INSERT INTO flashcards (id, entry_id, direction, state, stability, '
        'difficulty, due, last_reviewed_at, review_count, lapse_count, '
        'created_at, updated_at) VALUES '
        "('c-1', 'e-1', 'forward', 'review', 3.5, 5.1, "
        "'2026-10-18T08:00:00.000Z', '$t', 4, 1, '$t', '$t')",
      );

    final db = AppDatabase(schema.newConnection());
    final clock = FixedClock(DateTime.utc(2026, 10, 19, 9));
    final study = DriftStudyRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('new'),
    );
    final queue = await study.dueQueue(directions: {CardDirection.forward});
    expect(queue.map((c) => (c.entryId, c.state.state)), [
      ('e-1', CardState.review),
      ('e-2', CardState.newCard),
    ]);

    final (next, _) = await study.recordAnswer(
      entryId: 'e-1',
      direction: CardDirection.forward,
      sessionId: 's',
      outcome: ReviewOutcome.remembered,
    );
    final rows = await db.select(db.flashcards).get();
    expect(rows.single.id, 'c-1');
    expect(rows.single.reviewCount, 5);
    expect(rows.single.lapseCount, 1);
    expect(rows.single.due, next.due);
    expect(next.due.isAfter(clock.nowUtc()), isTrue);
    expect(await db.select(db.vocabularyEntries).get(), hasLength(2));
    expect(await db.select(db.vocabularyMeanings).get(), hasLength(2));
    await db.close();
  });
}
