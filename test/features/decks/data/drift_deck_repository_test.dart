import 'dart:io';

import 'package:ai_wortbox/core/config/app_config.dart';
import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  final start = DateTime.utc(2026, 10, 15, 8);
  late AppDatabase db;
  late FixedClock clock;
  late DriftDeckRepository repository;

  setUp(() {
    db = openTestDatabase();
    clock = FixedClock(start);
    repository = DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('deck'),
    );
  });
  tearDown(() => db.close());

  Matcher throwsValidation(DeckValidationError error) => throwsA(
    isA<DeckValidationException>().having(
      (e) => e.errors,
      'errors',
      contains(error),
    ),
  );

  test('creates a deck with German → Persian defaults', () async {
    final deck = await repository.createDeck(const DeckDraft(name: 'A1'));

    expect(deck.id, 'deck-1');
    expect(deck.name, 'A1');
    expect(deck.sourceLanguage, Language.german);
    expect(deck.definitionLanguage, Language.persian);
    expect(deck.dailyNewCardLimit, AppConfig.defaultDailyNewCardLimit);
    expect(deck.createdAt, start);
    expect(deck.updatedAt, start);
    expect(await repository.getDeck('deck-1'), deck);
  });

  test('stores the cleaned name and keeps Persian text intact', () async {
    final deck = await repository.createDeck(
      const DeckDraft(name: '  لغات   کتاب  Der Vorleser '),
    );
    expect(deck.name, 'لغات کتاب Der Vorleser');
    expect((await repository.getDeck(deck.id))!.name, deck.name);
  });

  test('lists decks newest first', () async {
    await repository.createDeck(const DeckDraft(name: 'First'));
    clock.advance(const Duration(minutes: 1));
    await repository.createDeck(const DeckDraft(name: 'Second'));

    final decks = await repository.getDecks();
    expect(decks.map((d) => d.name), ['Second', 'First']);
  });

  test('rejects invalid drafts without writing', () async {
    await expectLater(
      repository.createDeck(const DeckDraft(name: '  ')),
      throwsValidation(DeckValidationError.nameEmpty),
    );
    await expectLater(
      repository.createDeck(const DeckDraft(name: 'x', dailyNewCardLimit: -5)),
      throwsValidation(DeckValidationError.dailyLimitOutOfRange),
    );
    expect(await repository.getDecks(), isEmpty);
  });

  test('rejects case-insensitive duplicate names, including umlauts', () async {
    await repository.createDeck(const DeckDraft(name: 'Übungen'));
    await expectLater(
      repository.createDeck(const DeckDraft(name: '  übungen ')),
      throwsValidation(DeckValidationError.nameDuplicate),
    );
    await expectLater(
      repository.createDeck(const DeckDraft(name: 'ÜBUNGEN')),
      throwsValidation(DeckValidationError.nameDuplicate),
    );
    expect(await repository.getDecks(), hasLength(1));
  });

  test('getDeck returns null for unknown ids', () async {
    expect(await repository.getDeck('nope'), isNull);
  });

  test('watchDeckSummaries emits updates with entry counts', () async {
    final emissions = <List<DeckSummary>>[];
    final subscription = repository.watchDeckSummaries().listen(emissions.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();
    expect(emissions, [isEmpty]);

    final deck = await repository.createDeck(const DeckDraft(name: 'A1'));
    await pumpEventQueue();
    expect(emissions.last, [DeckSummary(deck: deck, entryCount: 0)]);

    await db
        .into(db.vocabularyEntries)
        .insert(
          VocabularyEntriesCompanion.insert(
            id: 'e1',
            deckId: deck.id,
            original: 'Haus',
            normalized: 'haus',
            sourceLanguage: 'de',
            definitionLanguage: 'fa',
            sourceType: VocabularySourceType.manual,
            enrichmentStatus: EnrichmentStatus.missing,
            createdAt: start,
            updatedAt: start,
          ),
        );

    await pumpEventQueue();
    expect(emissions.last, [DeckSummary(deck: deck, entryCount: 1)]);
  });

  test('watchDeck emits null after the deck disappears', () async {
    final deck = await repository.createDeck(const DeckDraft(name: 'A1'));
    final values = <Deck?>[];
    final subscription = repository.watchDeck(deck.id).listen(values.add);
    addTearDown(subscription.cancel);
    await pumpEventQueue();

    await (db.delete(db.decks)..where((d) => d.id.equals(deck.id))).go();
    await pumpEventQueue();

    expect(values, [deck, null]);
  });

  test('wraps database failures in StorageException', () async {
    // A database path that is a directory cannot be opened by SQLite.
    final dir = await Directory.systemTemp.createTemp('wortbox_broken');
    addTearDown(() => dir.delete(recursive: true));
    final broken = AppDatabase(NativeDatabase(File(dir.path)));
    addTearDown(broken.close);
    final brokenRepository = DriftDeckRepository(
      broken,
      clock: clock,
      ids: SequentialIdGenerator(),
    );

    await expectLater(
      brokenRepository.getDecks(),
      throwsA(isA<StorageException>()),
    );
    await expectLater(
      brokenRepository.createDeck(const DeckDraft(name: 'A1')),
      throwsA(isA<StorageException>()),
    );
  });

  test('decks persist across database restarts', () async {
    final dir = await Directory.systemTemp.createTemp('wortbox_test');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/ai_wortbox.sqlite');

    final first = AppDatabase(NativeDatabase(file));
    final created = await DriftDeckRepository(
      first,
      clock: clock,
      ids: const UuidIdGenerator(),
    ).createDeck(const DeckDraft(name: 'Persistent', dailyNewCardLimit: 7));
    await first.close();

    final second = AppDatabase(NativeDatabase(file));
    addTearDown(second.close);
    final reloaded = await DriftDeckRepository(
      second,
      clock: clock,
      ids: const UuidIdGenerator(),
    ).getDecks();

    expect(reloaded, [created]);
    expect(reloaded.single.sourceLanguage, Language.german);
    expect(reloaded.single.definitionLanguage, Language.persian);
    expect(reloaded.single.dailyNewCardLimit, 7);
  });
}
