import 'dart:io';

import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/review/data/drift_review_repository.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/review/domain/review_event.dart';
import 'package:ai_wortbox/features/settings/data/settings_store.dart';
import 'package:ai_wortbox/features/tags/data/drift_tag_repository.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/duplicate_detection.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_search.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  final start = DateTime.utc(2026, 10, 15, 8);
  late AppDatabase db;
  late FixedClock clock;
  late DriftVocabularyRepository vocab;
  late DriftTagRepository tags;
  late Deck a1;
  late Deck b1;

  Future<void> open(AppDatabase database) async {
    db = database;
    clock = FixedClock(start);
    vocab = DriftVocabularyRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('v'),
    );
    tags = DriftTagRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('t'),
    );
  }

  Future<VocabularyEntry> add(
    Deck deck,
    String word,
    List<String> meanings, {
    String? lemma,
  }) {
    clock.advance(const Duration(minutes: 1));
    return vocab.createEntry(
      VocabularyDraft(
        deckId: deck.id,
        original: word,
        lemma: lemma,
        meanings: [for (final m in meanings) VocabularyMeaning(m)],
      ),
    );
  }

  Future<List<String>> search(VocabularyQuery query, {int? limit}) async {
    final results =
        await (limit == null
                ? vocab.watchSearch(query)
                : vocab.watchSearch(query, limit: limit))
            .first;
    return results.map((e) => e.original).toList();
  }

  setUp(() async {
    await open(openTestDatabase());
    final decks = DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('deck'),
    );
    a1 = await decks.createDeck(const DeckDraft(name: 'A1'));
    b1 = await decks.createDeck(const DeckDraft(name: 'B1'));
  });
  tearDown(() => db.close());

  group('search', () {
    setUp(() async {
      await add(a1, 'das Haus', ['خانه']);
      await add(a1, 'Straße', ['خیابان']);
      await add(a1, 'ging', ['رفت'], lemma: 'gehen');
      await add(b1, 'sich freuen', ['خوشحال شدن', 'می‌روم']);
      // Arabic YEH and a diacritic, as some keyboards type it.
      await add(b1, 'Schiff', ['كشتيِ بزرگ']);
    });

    test(
      'empty query lists every entry, newest first; blank is empty',
      () async {
        expect(await search(const VocabularyQuery()), [
          'Schiff',
          'sich freuen',
          'ging',
          'Straße',
          'das Haus',
        ]);
        expect(await search(const VocabularyQuery(text: '   ')), hasLength(5));
      },
    );

    test('German: case-insensitive, substring, composed umlauts', () async {
      expect(await search(const VocabularyQuery(text: 'HAUS')), ['das Haus']);
      expect(await search(const VocabularyQuery(text: 'straß')), ['Straße']);
      // A decomposed umlaut (u + U+0308) finds the composed one.
      await add(a1, 'Mühe', ['زحمت']);
      expect(await search(const VocabularyQuery(text: 'mühe')), ['Mühe']);
    });

    test('the base form (lemma) is searched too', () async {
      expect(await search(const VocabularyQuery(text: 'gehen')), ['ging']);
    });

    test('Persian: letter variants, diacritics and ZWNJ are ignored', () async {
      expect(await search(const VocabularyQuery(text: 'خانه')), ['das Haus']);
      // Persian YEH/KAF finds Arabic YEH/KAF with a kasra.
      expect(await search(const VocabularyQuery(text: 'کشتی')), ['Schiff']);
      // With and without the zero-width non-joiner.
      expect(await search(const VocabularyQuery(text: 'میروم')), [
        'sich freuen',
      ]);
      expect(await search(const VocabularyQuery(text: 'می‌روم')), [
        'sich freuen',
      ]);
    });

    test('no results; SQL wildcards are matched literally', () async {
      expect(await search(const VocabularyQuery(text: 'Tisch')), isEmpty);
      expect(await search(const VocabularyQuery(text: '%')), isEmpty);
      expect(await search(const VocabularyQuery(text: '_')), isEmpty);
    });

    test('deck filter and result limit', () async {
      expect(await search(VocabularyQuery(deckId: b1.id)), [
        'Schiff',
        'sich freuen',
      ]);
      expect(await search(const VocabularyQuery(), limit: 2), hasLength(2));
    });

    test('edits update the search key; stored text is unchanged', () async {
      final haus = (await vocab.getEntries(a1.id))
          .firstWhere((e) => e.original == 'das Haus');
      await vocab.updateEntry(
        haus.id,
        VocabularyDraft(
          deckId: a1.id,
          original: 'das Haus',
          meanings: const [VocabularyMeaning('منزل')],
        ),
      );
      expect(await search(const VocabularyQuery(text: 'خانه')), isEmpty);
      expect(await search(const VocabularyQuery(text: 'منزل')), ['das Haus']);
      final schiff = (await vocab.getEntries(b1.id))
          .firstWhere((e) => e.original == 'Schiff');
      expect(schiff.meanings.single.text, 'كشتيِ بزرگ');
    });
  });

  group('difficult words', () {
    test('marking does not change content, updatedAt or review state, and '
        'filters the list', () async {
      final haus = await add(a1, 'das Haus', ['خانه']);
      await add(a1, 'Baum', ['درخت']);
      await db
          .into(db.flashcards)
          .insert(
            FlashcardsCompanion.insert(
              id: 'c1',
              entryId: haus.id,
              direction: CardDirection.forward,
              state: CardState.review,
              stability: const Value(3.2),
              due: start,
              createdAt: start,
              updatedAt: start,
            ),
          );
      final cardBefore = await db.select(db.flashcards).getSingle();

      clock.advance(const Duration(hours: 1));
      await vocab.setDifficult(haus.id, difficult: true);
      final marked = (await vocab.getEntry(haus.id))!;
      expect(marked.isDifficult, isTrue);
      expect(marked.markedDifficultAt, clock.nowUtc());
      expect(marked.updatedAt, haus.updatedAt);
      expect(marked.meanings, haus.meanings);
      expect(await db.select(db.flashcards).getSingle(), cardBefore);

      expect(await search(const VocabularyQuery(difficultOnly: true)), [
        'das Haus',
      ]);
      expect(await vocab.watchCounts().first, (total: 2, difficult: 1));

      await vocab.setDifficult(haus.id, difficult: false);
      expect((await vocab.getEntry(haus.id))!.isDifficult, isFalse);
      expect(await search(const VocabularyQuery(difficultOnly: true)), isEmpty);
    });

    test('an edit keeps the mark', () async {
      final haus = await add(a1, 'das Haus', ['خانه']);
      await vocab.setDifficult(haus.id, difficult: true);
      await vocab.updateEntry(
        haus.id,
        VocabularyDraft(
          deckId: a1.id,
          original: 'das Haus',
          meanings: const [
            VocabularyMeaning('خانه'),
            VocabularyMeaning('منزل'),
          ],
        ),
      );
      expect((await vocab.getEntry(haus.id))!.isDifficult, isTrue);
    });

    test('unknown id', () async {
      await expectLater(
        vocab.setDifficult('missing', difficult: true),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  group('tags', () {
    test('create, rename and validation', () async {
      final b1Tag = await tags.createTag('  B1  ');
      expect(b1Tag.name, 'B1');
      for (final duplicate in ['b1', ' B1', 'B1 ']) {
        await expectLater(
          tags.createTag(duplicate),
          throwsA(
            isA<TagValidationException>().having(
              (e) => e.error,
              'error',
              TagValidationError.nameDuplicate,
            ),
          ),
        );
      }
      await expectLater(
        tags.createTag('  '),
        throwsA(isA<TagValidationException>()),
      );
      await expectLater(
        tags.createTag('x' * 41),
        throwsA(isA<TagValidationException>()),
      );
      final travel = await tags.createTag('سفر');
      // Renaming to another case of its own name is allowed.
      expect((await tags.renameTag(b1Tag.id, 'b1')).name, 'b1');
      await expectLater(
        tags.renameTag(travel.id, 'B1'),
        throwsA(isA<TagValidationException>()),
      );
      expect((await tags.watchTags().first).map((t) => t.name), ['b1', 'سفر']);
    });

    test('assignments survive edits; deleting a tag keeps the words; '
        'deleting a word removes only its assignments', () async {
      final haus = await add(a1, 'das Haus', ['خانه']);
      final baum = await add(a1, 'Baum', ['درخت']);
      final a = await tags.createTag('A1');
      final travel = await tags.createTag('Reise');
      await tags.setEntryTags(haus.id, {a.id, travel.id});
      await tags.setEntryTags(baum.id, {a.id});

      await vocab.updateEntry(
        haus.id,
        VocabularyDraft(
          deckId: a1.id,
          original: 'das Haus',
          meanings: const [VocabularyMeaning('منزل')],
        ),
      );
      expect((await tags.watchEntryTags(haus.id).first).map((t) => t.name), [
        'A1',
        'Reise',
      ]);
      expect(await search(VocabularyQuery(tagId: travel.id)), ['das Haus']);
      expect(await search(VocabularyQuery(tagId: a.id, text: 'baum')), [
        'Baum',
      ]);
      expect(
        {for (final t in await tags.watchTags().first) t.name: t.entryCount},
        {'A1': 2, 'Reise': 1},
      );
      expect(await tags.getTagNamesForDeck(a1.id), {
        haus.id: ['A1', 'Reise'],
        baum.id: ['A1'],
      });

      await tags.deleteTag(travel.id);
      expect(await vocab.getEntry(haus.id), isNotNull);
      expect((await tags.watchEntryTags(haus.id).first).map((t) => t.name), [
        'A1',
      ]);

      await vocab.deleteEntry(baum.id);
      expect(
        {for (final t in await tags.watchTags().first) t.name: t.entryCount},
        {'A1': 1},
      );

      // Removing all tags of an entry.
      await tags.setEntryTags(haus.id, {});
      expect(await tags.watchEntryTags(haus.id).first, isEmpty);
    });

    test('imports add tags to created and merged entries, never to skipped '
        'rows; new tags are created once', () async {
      final existing = await add(a1, 'Baum', ['درخت']);
      final summary = await vocab.importEntries(a1.id, [
        ImportCandidate(
          rowNumber: 1,
          draft: VocabularyDraft(
            deckId: a1.id,
            original: 'Haus',
            meanings: const [VocabularyMeaning('خانه')],
          ),
          tags: const ['A1', 'Wohnen'],
        ),
        // Same word, new meaning, later in the file: merged into row 1.
        ImportCandidate(
          rowNumber: 2,
          draft: VocabularyDraft(
            deckId: a1.id,
            original: 'haus',
            meanings: const [VocabularyMeaning('منزل')],
          ),
          tags: const ['a1', 'Gebäude'],
        ),
        // Existing word, nothing new: skipped, so no tag.
        ImportCandidate(
          rowNumber: 3,
          draft: VocabularyDraft(
            deckId: a1.id,
            original: 'Baum',
            meanings: const [VocabularyMeaning('درخت')],
          ),
          tags: const ['Natur'],
        ),
      ], DuplicateStrategy.mergeMeanings);
      expect(summary.createdCount, 1);

      final haus = (await vocab.getEntries(a1.id))
          .firstWhere((e) => e.original == 'Haus');
      expect((await tags.watchEntryTags(haus.id).first).map((t) => t.name), [
        'A1',
        'Gebäude',
        'Wohnen',
      ]);
      expect(await tags.watchEntryTags(existing.id).first, isEmpty);
      expect((await tags.watchTags().first).map((t) => t.name), [
        'A1',
        'Gebäude',
        'Wohnen',
      ]);
    });
  });

  test('tags, difficult marks, review events and settings persist after '
      'closing and reopening the database file', () async {
    final dir = await Directory.systemTemp.createTemp('aiwb_restart');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/db.sqlite');

    await db.close();
    await open(AppDatabase(NativeDatabase(file)));
    final deck = await DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('d'),
    ).createDeck(const DeckDraft(name: 'Persist'));
    final haus = await add(deck, 'das Haus', ['خانه']);
    final tag = await tags.createTag('B1');
    await tags.setEntryTags(haus.id, {tag.id});
    await vocab.setDifficult(haus.id, difficult: true);
    await DriftReviewRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('r'),
    ).record(
      entryId: haus.id,
      sessionId: 's1',
      direction: CardDirection.reverse,
      outcome: ReviewOutcome.remembered,
    );
    await SettingsStore(db).writeAll({'reminder.enabled': 'true'});
    await db.close();

    await open(AppDatabase(NativeDatabase(file)));
    final reopened = (await vocab.getEntry(haus.id))!;
    expect(reopened.isDifficult, isTrue);
    expect((await tags.watchEntryTags(haus.id).first).map((t) => t.name), [
      'B1',
    ]);
    final events = await db.select(db.reviewEvents).get();
    expect(events.single.outcome, ReviewOutcome.remembered);
    expect(await SettingsStore(db).read('reminder.enabled'), 'true');
  });
}
