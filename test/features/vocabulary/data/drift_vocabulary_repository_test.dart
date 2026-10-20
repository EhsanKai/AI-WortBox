import 'dart:io';

import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/duplicate_detection.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

/// Fails on the [failAt]-th id, to simulate a crash in the middle of a write.
class FailingIdGenerator implements IdGenerator {
  FailingIdGenerator(this.failAt);

  final int failAt;
  int _calls = 0;

  @override
  String newId() {
    _calls++;
    if (_calls == failAt) throw StateError('simulated failure');
    return 'id-$_calls';
  }
}

void main() {
  final start = DateTime.utc(2026, 10, 15, 8);
  late AppDatabase db;
  late FixedClock clock;
  late DriftVocabularyRepository repository;
  late Deck deck;

  DriftVocabularyRepository repo({IdGenerator? ids}) =>
      DriftVocabularyRepository(
        db,
        clock: clock,
        ids: ids ?? SequentialIdGenerator('v'),
      );

  setUp(() async {
    db = openTestDatabase();
    clock = FixedClock(start);
    repository = repo();
    deck = await DriftDeckRepository(
      db,
      clock: clock,
      ids: SequentialIdGenerator('deck'),
    ).createDeck(const DeckDraft(name: 'A1'));
  });
  tearDown(() => db.close());

  VocabularyDraft draft(
    String word, [
    List<String> meanings = const [],
    VocabularySourceType source = VocabularySourceType.manual,
  ]) => VocabularyDraft(
    deckId: deck.id,
    original: word,
    meanings: [for (final m in meanings) VocabularyMeaning(m)],
    sourceType: source,
  );

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

  group('createEntry', () {
    test('stores content, meanings in order and deck languages', () async {
      final entry = await repository.createEntry(
        draft('  sich  Mühe geben ', ['زحمت کشیدن', 'تلاش کردن']).copyWith(),
      );
      expect(entry.original, 'sich Mühe geben');
      expect(entry.normalized, 'sich mühe geben');
      expect(entry.meanings.map((m) => m.text), ['زحمت کشیدن', 'تلاش کردن']);
      expect(entry.sourceLanguage, Language.german);
      expect(entry.definitionLanguage, Language.persian);
      expect(entry.sourceType, VocabularySourceType.manual);
      expect(entry.enrichmentStatus, EnrichmentStatus.ready);
      expect(entry.userEditedAt, start);
      expect(entry.createdAt, start);
      expect(await repository.getEntry(entry.id), entry);
    });

    test('entries without meanings are marked missing', () async {
      final entry = await repository.createEntry(draft('Haus'));
      expect(entry.enrichmentStatus, EnrichmentStatus.missing);
    });

    test('rejects invalid drafts and unknown decks asynchronously', () async {
      await expectLater(
        repository.createEntry(draft('  ')),
        throwsA(isA<VocabularyValidationException>()),
      );
      await expectLater(
        repository.createEntry(draft('Haus').copyWith(deckId: 'missing')),
        throwsA(
          isA<VocabularyValidationException>().having(
            (e) => e.errors,
            'errors',
            {VocabularyValidationError.deckNotFound},
          ),
        ),
      );
      expect(await repository.getEntries(deck.id), isEmpty);
    });
  });

  group('updateEntry', () {
    test(
      'line breaks in the word survive saving, loading and editing',
      () async {
        final created = await repository.createEntry(
          VocabularyDraft(
            deckId: deck.id,
            original: 'Der Nachbar\nDie Nachbarin',
            meanings: const [VocabularyMeaning('همسایه')],
          ),
        );
        expect(created.original, 'Der Nachbar\nDie Nachbarin');
        final row = await (db.select(
          db.vocabularyEntries,
        )..where((e) => e.id.equals(created.id))).getSingle();
        expect(row.original, 'Der Nachbar\nDie Nachbarin');
        final loaded = await repository.getEntry(created.id);
        final updated = await repository.updateEntry(
          created.id,
          VocabularyDraft.fromEntry(loaded!)
              .copyWith(original: '${loaded.original}\nDie Nachbarn'),
        );
        expect(updated.original, 'Der Nachbar\nDie Nachbarin\nDie Nachbarn');
        expect(
          (await repository.getEntry(created.id))!.original,
          updated.original,
        );
      },
    );

    test('replaces content and keeps review state untouched', () async {
      final entry = await repository.createEntry(draft('Bank', ['بانک']));
      await addFlashcard(entry.id);
      final cardBefore = await db.select(db.flashcards).getSingle();

      clock.advance(const Duration(hours: 1));
      final updated = await repository.updateEntry(
        entry.id,
        VocabularyDraft(
          deckId: deck.id,
          original: 'Bank',
          meanings: const [
            VocabularyMeaning('نیمکت'),
            VocabularyMeaning('بانک'),
          ],
          exampleSentence: 'Er sitzt auf der Bank.',
        ),
      );

      expect(updated.meanings.map((m) => m.text), ['نیمکت', 'بانک']);
      expect(updated.exampleSentence, 'Er sitzt auf der Bank.');
      expect(updated.createdAt, start);
      expect(updated.updatedAt, start.add(const Duration(hours: 1)));
      expect(updated.userEditedAt, start.add(const Duration(hours: 1)));
      expect(await db.select(db.flashcards).getSingle(), cardBefore);
      expect(await db.select(db.vocabularyMeanings).get(), hasLength(2));
    });

    test('clearing all meanings sets status back to missing', () async {
      final entry = await repository.createEntry(draft('Haus', ['خانه']));
      final updated = await repository.updateEntry(entry.id, draft('Haus'));
      expect(updated.enrichmentStatus, EnrichmentStatus.missing);
      expect(updated.meanings, isEmpty);
    });

    test('unknown ids throw NotFoundException', () async {
      await expectLater(
        repository.updateEntry('nope', draft('Haus')),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  test(
    'mergeIntoEntry adds only new meanings and keeps review state',
    () async {
      final entry = await repository.createEntry(draft('Bank', ['بانک']));
      await addFlashcard(entry.id);
      final cardBefore = await db.select(db.flashcards).getSingle();

      final merged = await repository.mergeIntoEntry(
        entry.id,
        draft('bank', ['بانک', 'نیمکت']),
      );
      expect(merged.original, 'Bank');
      expect(merged.meanings.map((m) => m.text), ['بانک', 'نیمکت']);
      expect(await db.select(db.flashcards).getSingle(), cardBefore);
    },
  );

  test('deleteEntry removes meanings and flashcards', () async {
    final entry = await repository.createEntry(draft('Haus', ['خانه']));
    await addFlashcard(entry.id);
    await repository.deleteEntry(entry.id);
    expect(await repository.getEntry(entry.id), isNull);
    expect(await db.select(db.vocabularyMeanings).get(), isEmpty);
    expect(await db.select(db.flashcards).get(), isEmpty);
    await expectLater(
      repository.deleteEntry(entry.id),
      throwsA(isA<NotFoundException>()),
    );
  });

  test(
    'findByNormalized matches case- and punctuation-insensitively',
    () async {
      await repository.createEntry(draft('Bank', ['بانک']));
      await repository.createEntry(draft('Bank', ['نیمکت']));
      await repository.createEntry(draft('Baum'));
      final matches = await repository.findByNormalized(deck.id, 'bank');
      expect(matches, hasLength(2));
    },
  );

  test('watchEntries emits newest first with meanings', () async {
    final emissions = <List<VocabularyEntry>>[];
    final sub = repository.watchEntries(deck.id).listen(emissions.add);
    addTearDown(sub.cancel);
    await pumpEventQueue();

    await repository.createEntry(draft('Haus', ['خانه']));
    clock.advance(const Duration(minutes: 1));
    await repository.createEntry(draft('Baum', ['درخت']));
    await pumpEventQueue();

    expect(emissions.first, isEmpty);
    expect(emissions.last.map((e) => e.original), ['Baum', 'Haus']);
    expect(emissions.last.last.meanings.single.text, 'خانه');
  });

  group('importEntries', () {
    List<ImportCandidate> candidates(List<(String, List<String>)> rows) => [
      for (final (i, (word, meanings)) in rows.indexed)
        ImportCandidate(
          rowNumber: i + 1,
          draft: draft(word, meanings, VocabularySourceType.csv),
        ),
    ];

    final rows = [
      ('Bank', ['بانک']),
      ('Bank', ['نیمکت']),
      ('Haus', ['منزل']),
      ('Schloss', <String>[]),
    ];

    Future<Map<String, List<String>>> contents() async => {
      for (final e in await repository.getEntries(deck.id))
        '${e.original}#${e.id}': e.meanings.map((m) => m.text).toList(),
    };

    test('skip strategy', () async {
      await repository.createEntry(draft('Haus', ['خانه']));
      final summary = await repository.importEntries(
        deck.id,
        candidates(rows),
        DuplicateStrategy.skip,
      );
      expect(
        (summary.createdCount, summary.mergedCount, summary.skippedCount),
        (2, 0, 2),
      );
      final entries = await repository.getEntries(deck.id);
      expect(entries.map((e) => e.original), containsAll(['Bank', 'Schloss']));
      final imported = entries.firstWhere((e) => e.original == 'Bank');
      expect(imported.sourceType, VocabularySourceType.csv);
      expect(imported.userEditedAt, isNull);
      expect(
        entries.firstWhere((e) => e.original == 'Schloss').enrichmentStatus,
        EnrichmentStatus.missing,
      );
    });

    test(
      'merge strategy folds rows into existing and earlier entries',
      () async {
        final haus = await repository.createEntry(draft('Haus', ['خانه']));
        await addFlashcard(haus.id);
        final cardBefore = await db.select(db.flashcards).getSingle();

        final summary = await repository.importEntries(
          deck.id,
          candidates(rows),
          DuplicateStrategy.mergeMeanings,
        );
        expect(
          (summary.createdCount, summary.mergedCount, summary.skippedCount),
          (2, 2, 0),
        );
        final entries = {
          for (final e in await repository.getEntries(deck.id)) e.original: e,
        };
        expect(entries['Bank']!.meanings.map((m) => m.text), ['بانک', 'نیمکت']);
        expect(entries['Haus']!.meanings.map((m) => m.text), ['خانه', 'منزل']);
        // Merging a CSV row is not a manual edit.
        expect(entries['Haus']!.userEditedAt, haus.userEditedAt);
        expect(await db.select(db.flashcards).getSingle(), cardBefore);
      },
    );

    test('keepSeparate strategy', () async {
      await repository.createEntry(draft('Haus', ['خانه']));
      final summary = await repository.importEntries(
        deck.id,
        candidates(rows),
        DuplicateStrategy.keepSeparate,
      );
      expect((summary.createdCount, summary.skippedCount), (4, 0));
      expect(await contents(), hasLength(5));
    });

    test('a failure in the middle rolls back the whole import', () async {
      await repository.createEntry(draft('Haus', ['خانه']));
      final before = await contents();

      // Ids are used for entries and meanings; fail after a few writes.
      final failing = repo(ids: FailingIdGenerator(4));
      await expectLater(
        failing.importEntries(
          deck.id,
          candidates(rows),
          DuplicateStrategy.keepSeparate,
        ),
        throwsA(isA<StorageException>()),
      );
      expect(await contents(), before);
    });

    test(
      'invalid candidates are rejected before anything is written',
      () async {
        await expectLater(
          repository.importEntries(deck.id, [
            ...candidates(rows),
            ImportCandidate(rowNumber: 9, draft: draft('')),
          ], DuplicateStrategy.skip),
          throwsA(isA<VocabularyValidationException>()),
        );
        expect(await repository.getEntries(deck.id), isEmpty);
      },
    );

    test('imports a large file in one transaction', () async {
      final many = [
        for (var i = 0; i < 2000; i++)
          ImportCandidate(
            rowNumber: i + 1,
            draft: draft('Wort$i', ['معنی $i'], VocabularySourceType.csv),
          ),
      ];
      final stopwatch = Stopwatch()..start();
      final summary = await repository.importEntries(
        deck.id,
        many,
        DuplicateStrategy.skip,
      );
      stopwatch.stop();
      expect(summary.createdCount, 2000);
      expect(await repository.getEntries(deck.id), hasLength(2000));
      // Generous bound; only guards against pathological slowness.
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 20)));
    });
  });

  test('entries persist across database restarts', () async {
    final dir = await Directory.systemTemp.createTemp('wortbox_vocab');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/ai_wortbox.sqlite');

    var fileDb = AppDatabase(NativeDatabase(file));
    final fileDeck = await DriftDeckRepository(
      fileDb,
      clock: clock,
      ids: const UuidIdGenerator(),
    ).createDeck(const DeckDraft(name: 'Persistent'));
    final created =
        await DriftVocabularyRepository(
          fileDb,
          clock: clock,
          ids: const UuidIdGenerator(),
        ).createEntry(
          VocabularyDraft(
            deckId: fileDeck.id,
            original: 'Mädchen',
            meanings: const [VocabularyMeaning('دختر')],
            exampleSentence: 'Das Mädchen liest.',
            exampleTranslation: 'دختر می‌خواند.',
          ),
        );
    await fileDb.close();

    fileDb = AppDatabase(NativeDatabase(file));
    addTearDown(fileDb.close);
    final reloaded = await DriftVocabularyRepository(
      fileDb,
      clock: clock,
      ids: const UuidIdGenerator(),
    ).getEntry(created.id);
    expect(reloaded, created);
  });
}
