import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/review/data/drift_study_repository.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/review/domain/review_event.dart';
import 'package:ai_wortbox/features/tags/data/drift_tag_repository.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DriftVocabularyRepository vocab;
  late List<VocabularyEntry> words;
  late Deck deck;
  late Deck other;
  final clock = FixedClock(DateTime.utc(2026, 10, 19, 9));

  setUp(() async {
    db = openTestDatabase();
    final decks = DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('d'),
    );
    deck = await decks.createDeck(const DeckDraft(name: 'A1'));
    other = await decks.createDeck(const DeckDraft(name: 'B1'));
    vocab = DriftVocabularyRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('v'),
    );
    words = [
      for (final (word, d) in [
        ('Haus', deck),
        ('Baum', deck),
        ('Straße', deck),
        ('Zug', other),
      ])
        await vocab.createEntry(
          VocabularyDraft(
            deckId: d.id,
            original: word,
            meanings: [VocabularyMeaning('معنی $word')],
          ),
        ),
    ];
    final tags = DriftTagRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('t'),
    );
    final tag = await tags.createTag('B1');
    for (final w in words) {
      await tags.setEntryTags(w.id, {tag.id});
    }
    final study = DriftStudyRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('s'),
    );
    for (final w in words) {
      await study.recordAnswer(
        entryId: w.id,
        direction: CardDirection.forward,
        sessionId: 's',
        outcome: ReviewOutcome.remembered,
      );
    }
  });
  tearDown(() => db.close());

  test('deletes exactly the selected words with their meanings, tags and '
      'scheduling state; history, decks and other words stay', () async {
    final deleted = await vocab.deleteEntries([words[0].id, words[2].id]);
    expect(deleted, 2);

    final remaining = await db.select(db.vocabularyEntries).get();
    expect(remaining.map((e) => e.original), unorderedEquals(['Baum', 'Zug']));
    final meanings = await db.select(db.vocabularyMeanings).get();
    expect(
      meanings.map((m) => m.entryId),
      unorderedEquals([words[1].id, words[3].id]),
    );
    expect(
      (await db.select(db.entryTags).get()).map((t) => t.entryId),
      unorderedEquals([words[1].id, words[3].id]),
    );
    expect(await db.select(db.tags).get(), hasLength(1));
    expect(
      (await db.select(db.flashcards).get()).map((c) => c.entryId),
      unorderedEquals([words[1].id, words[3].id]),
    );
    final events = await db.select(db.reviewEvents).get();
    expect(events, hasLength(4), reason: 'answers stay in the statistics');
    expect(events.where((e) => e.entryId == null), hasLength(2));
    expect(await db.select(db.decks).get(), hasLength(2));
    expect(await vocab.getEntry(words[1].id), words[1]);
  });

  test('unknown and repeated ids are ignored; an empty selection deletes '
      'nothing', () async {
    expect(await vocab.deleteEntries(const []), 0);
    expect(await vocab.deleteEntries([words[3].id, words[3].id, 'missing']), 1);
    expect(await db.select(db.vocabularyEntries).get(), hasLength(3));
  });

  test('large selections are deleted in one call', () async {
    final many = [
      for (var i = 0; i < 1200; i++)
        await vocab.createEntry(
          VocabularyDraft(
            deckId: other.id,
            original: 'Wort$i',
            meanings: const [VocabularyMeaning('x')],
          ),
        ),
    ];
    expect(await vocab.deleteEntries(many.map((e) => e.id)), 1200);
    expect(await db.select(db.vocabularyEntries).get(), hasLength(4));
  });
}
