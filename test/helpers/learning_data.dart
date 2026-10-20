import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/card_appearance/data/drift_card_appearance_repository.dart';
import 'package:ai_wortbox/features/card_appearance/domain/card_appearance.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/review/data/drift_review_repository.dart';
import 'package:ai_wortbox/features/review/data/drift_study_repository.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/review/domain/review_event.dart';
import 'package:ai_wortbox/features/sentence_practice/data/drift_sentence_practice_repository.dart';
import 'package:ai_wortbox/features/sentence_practice/domain/sentence_practice.dart';
import 'package:ai_wortbox/features/tags/data/drift_tag_repository.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';

/// Ids of the records [seedLearningData] created.
typedef SeededIds = ({
  String deck,
  String otherDeck,
  String haus,
  String gehen,
  String deleted,
  String tag,
});

/// Fills [db] with realistic learning data through the real repositories:
/// two decks, words with several meanings and optional fields, a tag, FSRS
/// review answers in both directions (so cards have real stability,
/// difficulty and due dates), free-practice events, a deleted word whose
/// history remains (entry id null), a difficult mark and sentence-practice
/// history.
Future<SeededIds> seedLearningData(
  AppDatabase db, {
  FixedClock? clock,
  String idPrefix = 'seed',
}) async {
  final c = clock ?? FixedClock(DateTime.utc(2026, 10, 15, 8));
  final ids = SequentialIdGenerator(idPrefix);
  final decks = DriftDeckRepository(db, clock: c, ids: ids);
  final words = DriftVocabularyRepository(db, clock: c, ids: ids);
  final tags = DriftTagRepository(db, clock: c, ids: ids);
  final study = DriftStudyRepository(db, clock: c, ids: ids);
  final reviews = DriftReviewRepository(db, clock: c, ids: ids);
  final practice = DriftSentencePracticeRepository(db, clock: c, ids: ids);

  final deck = await decks.createDeck(
    const DeckDraft(name: 'Kafka — Die Verwandlung', dailyNewCardLimit: 15),
  );
  final other = await decks.createDeck(const DeckDraft(name: 'Alltag'));
  final haus = await words.createEntry(
    VocabularyDraft(
      deckId: deck.id,
      original: 'Haus',
      lemma: 'Haus',
      partOfSpeech: 'Nomen',
      grammarInfo: 'das Haus, -es, Häuser',
      exampleSentence: 'Das Haus ist alt.',
      exampleTranslation: 'خانه قدیمی است.',
      notes: 'یادداشت',
      sourceContext: 'Er ging ins Haus.',
      meanings: const [
        VocabularyMeaning('خانه', explanation: 'ساختمان'),
        VocabularyMeaning('منزل'),
      ],
    ).cleaned(),
  );
  final gehen = await words.createEntry(
    VocabularyDraft(
      deckId: deck.id,
      original: 'gehen',
      meanings: const [VocabularyMeaning('رفتن')],
    ).cleaned(),
  );
  final deleted = await words.createEntry(
    VocabularyDraft(
      deckId: other.id,
      original: 'Ungeziefer',
      meanings: const [VocabularyMeaning('حشره')],
    ).cleaned(),
  );
  await words.createEntry(
    VocabularyDraft(deckId: other.id, original: 'ohne Bedeutung').cleaned(),
  );
  final tag = await tags.createTag('B1');
  await tags.setEntryTags(haus.id, {tag.id});
  await words.setDifficult(gehen.id, difficult: true);

  for (final (entry, direction, outcome) in [
    (haus.id, CardDirection.forward, ReviewOutcome.remembered),
    (haus.id, CardDirection.reverse, ReviewOutcome.forgotten),
    (gehen.id, CardDirection.forward, ReviewOutcome.forgotten),
    (deleted.id, CardDirection.forward, ReviewOutcome.remembered),
  ]) {
    await study.recordAnswer(
      entryId: entry,
      direction: direction,
      sessionId: 'session-1',
      outcome: outcome,
    );
    c.advance(const Duration(minutes: 3));
  }
  c.advance(const Duration(days: 1));
  await study.recordAnswer(
    entryId: haus.id,
    direction: CardDirection.forward,
    sessionId: 'session-2',
    outcome: ReviewOutcome.remembered,
  );
  await reviews.record(
    entryId: gehen.id,
    sessionId: 'free-1',
    direction: CardDirection.forward,
    outcome: ReviewOutcome.remembered,
  );
  await practice.record(
    entryId: haus.id,
    direction: SentencePracticeDirection.produce,
    level: SentenceLevel.b1,
    outcome: SentencePracticeOutcome.minorErrors,
  );
  // A styled card (mixed German/Persian highlights) and one on the word
  // that is deleted below (its appearance goes with it).
  final looks = DriftCardAppearanceRepository(db, clock: c);
  await looks.save(
    haus.id,
    CardAppearance(
      background: CardColor.mint,
      ink: CardInk.green,
      wordScale: 1.4,
      meaningScale: 1.2,
      highlightColor: HighlightColor.pink,
      highlights: {
        const CardHighlight(HighlightField.word, 'Haus'),
        const CardHighlight(HighlightField.meaning, 'منزل'),
      },
      sticker: CardSticker.star,
    ),
  );
  await looks.save(deleted.id, const CardAppearance(sticker: CardSticker.fire));
  // History of a deleted word is kept with a null word id.
  await words.deleteEntry(deleted.id);
  return (
    deck: deck.id,
    otherDeck: other.id,
    haus: haus.id,
    gehen: gehen.id,
    deleted: deleted.id,
    tag: tag.id,
  );
}

/// Every learning table as plain maps (column → value), for comparing two
/// databases exactly.
Future<Map<String, List<Map<String, Object?>>>> dumpLearningData(
  AppDatabase db,
) async {
  Future<List<Map<String, Object?>>> rows(String table, String order) async => [
    for (final row
        in await db.customSelect('SELECT * FROM $table ORDER BY $order').get())
      row.data,
  ];
  return {
    'decks': await rows('decks', 'id'),
    'vocabulary_entries': await rows('vocabulary_entries', 'id'),
    'vocabulary_meanings': await rows('vocabulary_meanings', 'id'),
    'flashcards': await rows('flashcards', 'id'),
    'tags': await rows('tags', 'id'),
    'entry_tags': await rows('entry_tags', 'entry_id, tag_id'),
    'review_events': await rows('review_events', 'id'),
    'sentence_practice_events': await rows('sentence_practice_events', 'id'),
    'card_appearances': await rows('card_appearances', 'entry_id'),
  };
}
