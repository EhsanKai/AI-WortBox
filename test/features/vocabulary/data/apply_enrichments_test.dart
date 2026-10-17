import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/duplicate_detection.dart';
import 'package:ai_wortbox/features/vocabulary/domain/enrichment_update.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  final start = DateTime.utc(2026, 10, 15, 8);
  late AppDatabase db;
  late FixedClock clock;
  late DriftVocabularyRepository repository;
  late Deck deck;

  final metadata = EnrichmentMetadata(
    provider: 'openrouter',
    model: 'anthropic/claude-haiku-5.5',
    generatedAt: DateTime.utc(2026, 10, 16, 9),
    isAmbiguous: true,
  );

  setUp(() async {
    db = openTestDatabase();
    clock = FixedClock(start);
    repository = DriftVocabularyRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('id'),
    );
    deck = await DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('deck'),
    ).createDeck(const DeckDraft(name: 'Buch'));
  });
  tearDown(() => db.close());

  Future<VocabularyEntry> scanned(String word, {String? context}) async {
    // Scanned words arrive through the import path (no userEditedAt).
    final summary = await repository.importEntries(deck.id, [
      ImportCandidate(
        rowNumber: 1,
        draft: VocabularyDraft(
          deckId: deck.id,
          original: word,
          sourceContext: context,
          sourceType: VocabularySourceType.image,
        ),
      ),
    ], DuplicateStrategy.skip);
    expect(summary.createdCount, 1);
    return (await repository.getEntries(deck.id))
        .firstWhere((e) => e.original == word);
  }

  Future<void> addFlashcard(String entryId) => db
      .into(db.flashcards)
      .insert(
        FlashcardsCompanion.insert(
          id: 'card-$entryId',
          entryId: entryId,
          direction: CardDirection.forward,
          state: CardState.review,
          due: start.add(const Duration(days: 3)),
          createdAt: start,
          updatedAt: start,
          stability: const Value(5.5),
          difficulty: const Value(6.1),
          reviewCount: const Value(4),
          lapseCount: const Value(1),
        ),
      );

  test('fills an entry without meanings and marks it ready', () async {
    final ging = await scanned(
      'ging',
      context: 'Am Morgen ging sie in die Stadt.',
    );
    expect(ging.enrichmentStatus, EnrichmentStatus.missing);
    clock.advance(const Duration(minutes: 5));

    final [saved] = await repository.applyEnrichments([
      EnrichmentUpdate(
        entryId: ging.id,
        expectedUpdatedAt: ging.updatedAt,
        metadata: metadata,
        addMeanings: const [VocabularyMeaning('رفت', explanation: 'گذشته')],
        lemma: 'gehen',
        partOfSpeech: 'Verb',
        grammarInfo: 'ging, ist gegangen',
        exampleSentence: 'Wir gehen ins Kino.',
        exampleTranslation: 'ما به سینما می‌رویم.',
      ),
    ]);

    expect(saved.original, 'ging');
    expect(saved.sourceContext, 'Am Morgen ging sie in die Stadt.');
    expect(saved.sourceType, VocabularySourceType.image);
    expect(saved.meanings, const [
      VocabularyMeaning('رفت', explanation: 'گذشته'),
    ]);
    expect(saved.lemma, 'gehen');
    expect(saved.partOfSpeech, 'Verb');
    expect(saved.grammarInfo, 'ging, ist gegangen');
    expect(saved.exampleSentence, 'Wir gehen ins Kino.');
    expect(saved.exampleTranslation, 'ما به سینما می‌رویم.');
    expect(saved.enrichmentStatus, EnrichmentStatus.ready);
    expect(saved.enrichmentMetadata, metadata);
    expect(saved.userEditedAt, isNull);
    expect(saved.updatedAt, start.add(const Duration(minutes: 5)));
  });

  test('existing meanings and user-edited fields are kept; meanings are '
      'only appended', () async {
    final bank = await repository.createEntry(
      VocabularyDraft(
        deckId: deck.id,
        original: 'Bank',
        meanings: const [VocabularyMeaning('بانک')],
        notes: 'یادداشت من',
        grammarInfo: 'die Bank, -en',
      ),
    );
    final editedAt = bank.userEditedAt;
    expect(editedAt, isNotNull);

    final [saved] = await repository.applyEnrichments([
      EnrichmentUpdate(
        entryId: bank.id,
        expectedUpdatedAt: bank.updatedAt,
        metadata: metadata,
        addMeanings: const [VocabularyMeaning('نیمکت')],
        // grammarInfo not chosen (null): unchanged.
      ),
    ]);
    expect(saved.meanings.map((m) => m.text), ['بانک', 'نیمکت']);
    expect(saved.grammarInfo, 'die Bank, -en');
    expect(saved.notes, 'یادداشت من');
    expect(saved.userEditedAt, editedAt);
  });

  test('review state is never modified', () async {
    final ging = await scanned('ging');
    await addFlashcard(ging.id);
    final cardBefore = await db.select(db.flashcards).getSingle();

    await repository.applyEnrichments([
      EnrichmentUpdate(
        entryId: ging.id,
        expectedUpdatedAt: ging.updatedAt,
        metadata: metadata,
        addMeanings: const [VocabularyMeaning('رفت')],
      ),
    ]);
    expect(await db.select(db.flashcards).getSingle(), cardBefore);
  });

  test('a change since the proposal writes nothing at all', () async {
    final a = await scanned('ging');
    final b = await scanned('Mühe');
    // The user edits "Mühe" while the proposal is under review.
    clock.advance(const Duration(minutes: 1));
    await repository.updateEntry(
      b.id,
      VocabularyDraft(
        deckId: deck.id,
        original: 'Mühe',
        meanings: const [VocabularyMeaning('زحمت')],
      ),
    );

    await expectLater(
      repository.applyEnrichments([
        EnrichmentUpdate(
          entryId: a.id,
          expectedUpdatedAt: a.updatedAt,
          metadata: metadata,
          addMeanings: const [VocabularyMeaning('رفت')],
        ),
        EnrichmentUpdate(
          entryId: b.id,
          expectedUpdatedAt: b.updatedAt,
          metadata: metadata,
          addMeanings: const [VocabularyMeaning('تلاش')],
        ),
      ]),
      throwsA(
        isA<EnrichmentConflictException>().having(
          (e) => e.entryIds,
          'entryIds',
          {b.id},
        ),
      ),
    );
    expect(await repository.getEntry(a.id), a);
    expect((await repository.getEntry(b.id))!.meanings.map((m) => m.text), [
      'زحمت',
    ]);
  });

  test('an invalid update rolls back the whole batch', () async {
    final a = await scanned('ging');
    final b = await scanned('Mühe');
    await expectLater(
      repository.applyEnrichments([
        EnrichmentUpdate(
          entryId: a.id,
          expectedUpdatedAt: a.updatedAt,
          metadata: metadata,
          addMeanings: const [VocabularyMeaning('رفت')],
        ),
        EnrichmentUpdate(
          entryId: b.id,
          expectedUpdatedAt: b.updatedAt,
          metadata: metadata,
          grammarInfo: 'x' * 5000, // over the field limit
        ),
      ]),
      throwsA(isA<VocabularyValidationException>()),
    );
    expect(await repository.getEntry(a.id), a);
    expect(await repository.getEntry(b.id), b);
  });

  test('a deleted entry fails without writing anything', () async {
    final a = await scanned('ging');
    await expectLater(
      repository.applyEnrichments([
        EnrichmentUpdate(
          entryId: a.id,
          expectedUpdatedAt: a.updatedAt,
          metadata: metadata,
          addMeanings: const [VocabularyMeaning('رفت')],
        ),
        EnrichmentUpdate(
          entryId: 'missing',
          expectedUpdatedAt: start,
          metadata: metadata,
          addMeanings: const [VocabularyMeaning('رفت')],
        ),
      ]),
      throwsA(isA<NotFoundException>()),
    );
    expect(await repository.getEntry(a.id), a);
  });

  test('repeated meanings in an update are not stored twice', () async {
    final ging = await scanned('ging');
    final [saved] = await repository.applyEnrichments([
      EnrichmentUpdate(
        entryId: ging.id,
        expectedUpdatedAt: ging.updatedAt,
        metadata: metadata,
        addMeanings: const [VocabularyMeaning('رفت'), VocabularyMeaning('رفت')],
      ),
    ]);
    expect(saved.meanings, hasLength(1));
  });

  test('an empty list writes nothing', () async {
    expect(await repository.applyEnrichments(const []), isEmpty);
  });
}
