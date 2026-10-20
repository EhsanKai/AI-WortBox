import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/about/domain/release_notes.dart';
import 'package:ai_wortbox/features/backup/data/backup_codec.dart';
import 'package:ai_wortbox/features/backup/data/backup_service.dart';
import 'package:ai_wortbox/features/backup/data/safety_backup_store.dart';
import 'package:ai_wortbox/features/card_appearance/data/drift_card_appearance_repository.dart';
import 'package:ai_wortbox/features/card_appearance/domain/card_appearance.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/review/data/drift_study_repository.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/review/domain/review_event.dart';
import 'package:ai_wortbox/features/settings/data/settings_store.dart';
import 'package:ai_wortbox/features/tags/data/drift_tag_repository.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/backup_fakes.dart';
import '../../helpers/learning_data.dart';
import '../../helpers/test_database.dart';

const app = InstalledVersion(version: '1.0.0', buildNumber: '3');

BackupService serviceFor(
  AppDatabase db, {
  SafetyBackupStore? safety,
  Clock? clock,
}) => BackupService(
  db,
  clock: clock ?? FixedClock(DateTime.utc(2026, 10, 20, 12)),
  ids: SequentialIdGenerator('restore'),
  safety: safety ?? MemorySafetyStore(),
);

/// Decodes a backup file, applies [edit] to its JSON and re-encodes it
/// with a recomputed checksum (so only [edit]'s change is tested).
Uint8List edited(
  Uint8List bytes,
  void Function(Map<String, dynamic> file) edit, {
  bool fixChecksum = true,
}) {
  final file = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  edit(file);
  if (fixChecksum) {
    file['checksum'] = {
      'algorithm': 'sha256',
      'value': sha256.convert(utf8.encode(jsonEncode(file['data']))).toString(),
    };
  }
  return Uint8List.fromList(utf8.encode(jsonEncode(file)));
}

List<dynamic> rows(Map<String, dynamic> file, String table) =>
    (file['data'] as Map<String, dynamic>)[table] as List<dynamic>;

Map<String, dynamic> row(
  Map<String, dynamic> file,
  String table, [
  int index = 0,
]) => rows(file, table)[index] as Map<String, dynamic>;

Map<String, dynamic> counts(Map<String, dynamic> file) =>
    file['counts'] as Map<String, dynamic>;

void main() {
  late AppDatabase source;
  late SeededIds seeded;
  late Uint8List backup;

  setUp(() async {
    source = openTestDatabase();
    seeded = await seedLearningData(source);
    backup = await serviceFor(source).createBackup(app: app);
  });
  tearDown(() => source.close());

  group('round trip', () {
    test('replace restore into an empty database reproduces every learning '
        'table exactly (words, meanings, tags, FSRS cards, review and '
        'sentence-practice history)', () async {
      final target = openTestDatabase();
      addTearDown(target.close);
      final service = serviceFor(target);
      final validated = await service.read(backup);
      expect(validated.manifest.formatVersion, BackupCodec.formatVersion);
      expect(validated.manifest.schemaVersion, source.schemaVersion);
      expect(validated.manifest.appVersion, '1.0.0');
      expect(validated.manifest.appBuild, '3');
      expect(validated.manifest.exportedAt, DateTime.utc(2026, 10, 20, 12));

      final result = await service.restore(validated, RestoreMode.replace);
      expect(result.entriesAdded, 3);
      expect(await dumpLearningData(target), await dumpLearningData(source));
    });

    test('the backup contains the expected records and counts', () async {
      final v = await serviceFor(source).read(backup);
      expect(v.manifest.counts.toJson(), {
        'decks': 2,
        'entries': 3,
        'meanings': 3,
        'flashcards': 3,
        'tags': 1,
        'entryTags': 1,
        'reviewEvents': 6,
        'sentencePractice': 1,
        'cardAppearances': 1,
      });
      // The deleted word's history is kept with no word.
      expect(
        v.snapshot.reviewEvents.where((r) => r.entryId == null),
        hasLength(1),
      );
    });

    test('FSRS scheduling survives exactly: state, step, stability, '
        'difficulty, due, counts and scheduler version, and the due queue '
        'is the same afterwards', () async {
      final target = openTestDatabase();
      addTearDown(target.close);
      final service = serviceFor(target);
      await service.restore(await service.read(backup), RestoreMode.replace);

      final before = await source.select(source.flashcards).get();
      final after = await target.select(target.flashcards).get();
      expect(after, before);
      expect(before.map((c) => c.stability), everyElement(isNotNull));
      expect(before.map((c) => c.reviewCount), contains(2));

      final now = FixedClock(DateTime.utc(2026, 10, 30));
      Future<List<Object>> queue(AppDatabase db) async => [
        for (final c in await DriftStudyRepository(
          db,
          clock: now,
          ids: SequentialIdGenerator(),
        ).dueQueue(directions: CardDirection.values.toSet()))
          (c.entryId, c.direction, c.state.due),
      ];
      expect(await queue(target), await queue(source));
    });

    test(
      'review history is preserved, including events of deleted words',
      () async {
        final target = openTestDatabase();
        addTearDown(target.close);
        final service = serviceFor(target);
        await service.restore(await service.read(backup), RestoreMode.replace);
        expect(
          await target.select(target.reviewEvents).get(),
          await source.select(source.reviewEvents).get(),
        );
      },
    );

    test(
      'a file-backed database keeps the restored data after reopening',
      () async {
        final dir = await Directory.systemTemp.createTemp('wortbox_backup');
        addTearDown(() => dir.delete(recursive: true));
        final file = File('${dir.path}/restore.sqlite');
        var target = AppDatabase(NativeDatabase(file));
        final service = serviceFor(target);
        await service.restore(await service.read(backup), RestoreMode.replace);
        await target.close();

        target = AppDatabase(NativeDatabase(file));
        addTearDown(target.close);
        expect(await dumpLearningData(target), await dumpLearningData(source));
      },
    );
  });

  group('secrets and settings', () {
    test('settings, AI preferences and anything key-like are never in a '
        'backup', () async {
      await SettingsStore(source).writeAll({
        'review.direction': 'both',
        'ai.freeOnly': 'false',
        'ai.secretish': 'sk-or-v1-0000000000000000000000000000test1234',
        'aicache.x': 'cached',
      });
      final text = utf8.decode(await serviceFor(source).createBackup());
      expect(text, isNot(contains('sk-or-')));
      expect(text, isNot(contains('freeOnly')));
      expect(text, isNot(contains('aicache')));
      expect(text, isNot(contains('review.direction')));
    });

    test('restoring never changes the device settings', () async {
      final target = openTestDatabase();
      addTearDown(target.close);
      await SettingsStore(target).writeAll({'ai.freeOnly': 'true'});
      final service = serviceFor(target);
      await service.restore(await service.read(backup), RestoreMode.replace);
      expect(await SettingsStore(target).read('ai.freeOnly'), 'true');
    });
  });

  group('validation (nothing is written)', () {
    Future<BackupError> errorOf(Uint8List bytes) async {
      try {
        await serviceFor(source).read(bytes);
      } on BackupException catch (e) {
        return e.error;
      }
      fail('accepted an invalid backup');
    }

    test('not a backup', () async {
      expect(
        await errorOf(Uint8List.fromList(utf8.encode('Haus;خانه'))),
        BackupError.notBackup,
      );
      expect(
        await errorOf(Uint8List.fromList([0xFF, 0xFE, 0x00])),
        BackupError.notBackup,
      );
      expect(
        await errorOf(Uint8List.fromList(utf8.encode('{"a": 1}'))),
        BackupError.notBackup,
      );
      expect(
        await errorOf(Uint8List.fromList(utf8.encode('[]'))),
        BackupError.notBackup,
      );
    });

    test('a truncated file', () async {
      expect(
        await errorOf(Uint8List.sublistView(backup, 0, backup.length ~/ 2)),
        BackupError.notBackup,
      );
    });

    test('unsupported format version and newer schema', () async {
      expect(
        await errorOf(edited(backup, (f) => f['formatVersion'] = 2)),
        BackupError.unsupportedVersion,
      );
      expect(
        await errorOf(edited(backup, (f) => f['formatVersion'] = 0)),
        BackupError.unsupportedVersion,
      );
      expect(
        await errorOf(edited(backup, (f) => f['schemaVersion'] = 99)),
        BackupError.newerSchema,
      );
    });

    test('changed content without a matching checksum', () async {
      expect(
        await errorOf(
          edited(backup, (f) {
            row(f, 'decks')['dailyNewCardLimit'] = 99;
          }, fixChecksum: false),
        ),
        BackupError.corrupted,
      );
    });

    test('missing required fields', () async {
      for (final path in [
        ('decks', 'name'),
        ('entries', 'original'),
        ('entries', 'deckId'),
        ('meanings', 'meaning'),
        ('flashcards', 'due'),
        ('reviewEvents', 'outcome'),
        ('sentencePractice', 'level'),
      ]) {
        expect(
          await errorOf(
            edited(backup, (f) {
              row(f, path.$1).remove(path.$2);
            }),
          ),
          BackupError.missingField,
          reason: '$path',
        );
      }
      expect(
        await errorOf(edited(backup, (f) => f.remove('data'))),
        BackupError.missingField,
      );
    });

    test('invalid values', () async {
      final cases = <String, void Function(Map<String, dynamic>)>{
        'enum': (f) => row(f, 'flashcards')['state'] = 'mastered',
        'date': (f) => row(f, 'flashcards')['due'] = 'tomorrow',
        'local date': (f) =>
            row(f, 'flashcards')['due'] = '2026-10-20T10:00:00',
        'range': (f) => row(f, 'decks')['dailyNewCardLimit'] = 5000,
        'type': (f) => row(f, 'flashcards')['reviewCount'] = '2',
        'negative': (f) => row(f, 'flashcards')['lapseCount'] = -1,
        'empty word': (f) => row(f, 'entries')['original'] = '',
        'metadata': (f) => row(f, 'entries')['enrichmentMetadata'] = '{',
        'local day': (f) => row(f, 'reviewEvents')['localDay'] = '2026-13-45',
        'list item': (f) => rows(f, 'meanings').add(3),
        'counts': (f) => counts(f)['entries'] = 4,
      };
      for (final MapEntry(:key, :value) in cases.entries) {
        expect(
          await errorOf(edited(backup, value)),
          BackupError.invalidValue,
          reason: key,
        );
      }
    });

    test('duplicate ids and unique values', () async {
      final cases = <String, void Function(Map<String, dynamic>)>{
        'entry id': (f) {
          final list = rows(f, 'entries');
          list.add(Map.of(list.first as Map));
        },
        'deck name': (f) {
          final list = rows(f, 'decks');
          list.add({
            ...list.first as Map,
            'id': 'other',
            'name': 'KAFKA — die verwandlung',
          });
        },
        'meaning position': (f) {
          final list = rows(f, 'meanings');
          list.add({...list.first as Map, 'id': 'm-x'});
        },
        'card direction': (f) {
          final list = rows(f, 'flashcards');
          list.add({...list.first as Map, 'id': 'c-x'});
        },
      };
      for (final MapEntry(:key, :value) in cases.entries) {
        expect(
          await errorOf(edited(backup, value)),
          BackupError.duplicateId,
          reason: key,
        );
      }
    });

    test('references to records that are not in the file', () async {
      final cases = <String, void Function(Map<String, dynamic>)>{
        'deck': (f) => row(f, 'entries')['deckId'] = 'nope',
        'meaning': (f) => row(f, 'meanings')['entryId'] = 'nope',
        'card': (f) => row(f, 'flashcards')['entryId'] = 'nope',
        'tag': (f) => row(f, 'entryTags')['tagId'] = 'nope',
        'review': (f) => row(f, 'reviewEvents')['entryId'] = 'nope',
      };
      for (final MapEntry(:key, :value) in cases.entries) {
        expect(
          await errorOf(edited(backup, value)),
          BackupError.brokenReference,
          reason: key,
        );
      }
    });

    test('the error names the location, never content', () async {
      try {
        await serviceFor(
          source,
        ).read(edited(backup, (f) => row(f, 'entries', 1).remove('original')));
        fail('accepted');
      } on BackupException catch (e) {
        expect(e.location, 'data.entries[1].original');
        expect(e.toString(), isNot(contains('Haus')));
      }
    });

    test(
      'a large file is validated off the UI isolate with the same result',
      () async {
        final big = edited(backup, (f) {
          final entries = rows(f, 'entries');
          final meanings = rows(f, 'meanings');
          for (var i = 0; i < 1500; i++) {
            entries.add({
              ...entries.first as Map,
              'id': 'bulk-$i',
              'original': 'Wort $i',
            });
            meanings.add({
              ...meanings.first as Map,
              'id': 'bm-$i',
              'entryId': 'bulk-$i',
            });
          }
          counts(f)['entries'] = entries.length;
          counts(f)['meanings'] = meanings.length;
        });
        expect(big.length, greaterThan(256 * 1024));
        final v = await serviceFor(source).read(big);
        expect(v.snapshot.entries, hasLength(1503));
      },
    );
  });

  group('replace', () {
    test(
      'replaces everything after a safety copy of the current data',
      () async {
        final target = openTestDatabase();
        addTearDown(target.close);
        final safety = MemorySafetyStore();
        final service = serviceFor(target, safety: safety);
        final deck = await DriftDeckRepository(
          target,
          clock: FixedClock(DateTime.utc(2026, 10, 1)),
          ids: SequentialIdGenerator('local'),
        ).createDeck(const DeckDraft(name: 'Nur lokal'));
        await DriftVocabularyRepository(
          target,
          clock: FixedClock(DateTime.utc(2026, 10, 1)),
          ids: SequentialIdGenerator('local'),
        ).createEntry(
          VocabularyDraft(
            deckId: deck.id,
            original: 'lokal',
            meanings: const [VocabularyMeaning('محلی')],
          ).cleaned(),
        );
        final localBefore = await dumpLearningData(target);

        await service.restore(await service.read(backup), RestoreMode.replace);
        expect(await dumpLearningData(target), await dumpLearningData(source));

        // The safety copy restores the previous state exactly.
        expect(safety.saved, hasLength(1));
        final undo = serviceFor(target);
        await undo.restore(
          await undo.read(safety.saved.single.$2),
          RestoreMode.replace,
        );
        expect(await dumpLearningData(target), localBefore);
      },
    );

    test('nothing changes when the safety copy cannot be saved', () async {
      final target = openTestDatabase();
      addTearDown(target.close);
      await seedLearningData(target, idPrefix: 'local');
      final before = await dumpLearningData(target);
      final service = serviceFor(
        target,
        safety: MemorySafetyStore()..failing = true,
      );
      final validated = await service.read(backup);
      await expectLater(
        service.restore(validated, RestoreMode.replace),
        throwsA(
          isA<BackupException>().having(
            (e) => e.error,
            'error',
            BackupError.safetyCopyFailed,
          ),
        ),
      );
      expect(await dumpLearningData(target), before);
    });

    test('a failure while writing rolls the whole restore back', () async {
      final target = openTestDatabase();
      addTearDown(target.close);
      await seedLearningData(target, idPrefix: 'local');
      final before = await dumpLearningData(target);
      final service = serviceFor(target);
      final valid = await service.read(backup);
      // Bypasses validation: a card for a word that does not exist fails
      // the foreign key in the middle of the restore.
      final broken = ValidatedBackup(
        valid.manifest,
        BackupSnapshot(
          decks: valid.snapshot.decks,
          entries: valid.snapshot.entries,
          meanings: valid.snapshot.meanings,
          flashcards: [
            ...valid.snapshot.flashcards,
            valid.snapshot.flashcards.first.copyWith(
              id: 'x',
              entryId: 'missing',
            ),
          ],
        ),
      );
      await expectLater(
        service.restore(broken, RestoreMode.replace),
        throwsA(isA<StorageException>()),
      );
      expect(await dumpLearningData(target), before);
    });
  });

  group('merge', () {
    late AppDatabase target;
    late FixedClock clock;
    late DriftVocabularyRepository words;
    late DriftStudyRepository study;

    setUp(() async {
      target = openTestDatabase();
      clock = FixedClock(DateTime.utc(2026, 10, 18, 8));
      final ids = SequentialIdGenerator('local');
      words = DriftVocabularyRepository(target, clock: clock, ids: ids);
      study = DriftStudyRepository(target, clock: clock, ids: ids);
    });
    tearDown(() => target.close());

    test('into an empty database it adds everything', () async {
      final service = serviceFor(target);
      final r = await service.restore(
        await service.read(backup),
        RestoreMode.merge,
      );
      expect(r.decksAdded, 2);
      expect(r.entriesAdded, 3);
      expect(r.entriesAlreadyPresent, 0);
      expect(await dumpLearningData(target), await dumpLearningData(source));
    });

    test(
      'merging the same backup twice adds nothing the second time',
      () async {
        final service = serviceFor(target);
        await service.restore(await service.read(backup), RestoreMode.merge);
        final once = await dumpLearningData(target);
        final r = await service.restore(
          await service.read(backup),
          RestoreMode.merge,
        );
        expect(r.entriesAdded, 0);
        expect(r.entriesAlreadyPresent, 3);
        expect(r.flashcardsAdded, 0);
        expect(r.reviewEventsAdded, 0);
        expect(r.sentencePracticeAdded, 0);
        expect(await dumpLearningData(target), once);
      },
    );

    test('keeps every local record unchanged, including FSRS state, and '
        'never deletes anything', () async {
      final service = serviceFor(target);
      await service.restore(await service.read(backup), RestoreMode.merge);
      // The device moves on: Haus is reviewed again and edited.
      clock.advance(const Duration(days: 5));
      await study.recordAnswer(
        entryId: seeded.haus,
        direction: CardDirection.forward,
        sessionId: 'later',
        outcome: ReviewOutcome.forgotten,
      );
      final haus = (await words.getEntry(seeded.haus))!;
      await words.updateEntry(
        haus.id,
        VocabularyDraft.fromEntry(haus).copyWith(
          meanings: [...haus.meanings, const VocabularyMeaning('ساختمان')],
        ),
      );
      final local = await dumpLearningData(target);

      // The older backup is merged again: nothing local is overwritten.
      final r = await service.restore(
        await service.read(backup),
        RestoreMode.merge,
      );
      expect(r.flashcardsKept, 3);
      expect(await dumpLearningData(target), local);
    });

    test('a deck with the same name is reused; a word already there with no '
        'new meaning is not duplicated; a word with other meanings is added '
        'separately; tags are matched by name', () async {
      final ids = SequentialIdGenerator('mine');
      final deck = await DriftDeckRepository(
        target,
        clock: clock,
        ids: ids,
      ).createDeck(const DeckDraft(name: 'kafka — die verwandlung'));
      final mine = DriftVocabularyRepository(target, clock: clock, ids: ids);
      final myHaus = await mine.createEntry(
        VocabularyDraft(
          deckId: deck.id,
          original: 'Haus',
          meanings: const [
            VocabularyMeaning('خانه'),
            VocabularyMeaning('منزل'),
            VocabularyMeaning('بنا'),
          ],
        ).cleaned(),
      );
      final myGehen = await mine.createEntry(
        VocabularyDraft(
          deckId: deck.id,
          original: 'gehen',
          meanings: const [VocabularyMeaning('راه رفتن')],
        ).cleaned(),
      );
      await DriftTagRepository(target, clock: clock, ids: ids).createTag('b1');

      final service = serviceFor(target);
      final r = await service.restore(
        await service.read(backup),
        RestoreMode.merge,
      );
      expect(r.decksMatched, 1);
      expect(r.decksAdded, 1);
      expect(r.tagsAdded, 0);
      expect(r.entriesAlreadyPresent, 1); // Haus: no new meaning
      expect(r.entriesAdded, 2); // gehen (other meaning), ohne Bedeutung

      final inDeck = await mine.getEntries(deck.id);
      expect(
        inDeck.map((e) => e.original),
        unorderedEquals(['Haus', 'gehen', 'gehen']),
      );
      expect(
        inDeck.firstWhere((e) => e.id == myGehen.id).meanings.single.text,
        'راه رفتن',
      );
      // Haus's scheduling from the backup is not attached to the local
      // word; its review history is.
      expect(await study.cardState(myHaus.id, CardDirection.forward), isNull);
      final hausEvents = await (target.select(
        target.reviewEvents,
      )..where((e) => e.entryId.equals(myHaus.id))).get();
      expect(hausEvents, hasLength(3));
      final tagged = await target.select(target.entryTags).get();
      expect(tagged.single.entryId, myHaus.id);
    });

    test('does not touch settings', () async {
      await SettingsStore(target).writeAll({'review.direction': 'reverse'});
      final service = serviceFor(target);
      await service.restore(await service.read(backup), RestoreMode.merge);
      expect(await SettingsStore(target).read('review.direction'), 'reverse');
    });
  });

  group('card appearance (schema v4)', () {
    test(
      'is backed up and restored exactly, and the file says schema 4 '
      '(build 3, schema 3, rejects it instead of dropping appearances)',
      () async {
        final json = jsonDecode(utf8.decode(backup)) as Map<String, dynamic>;
        expect(json['schemaVersion'], 4);
        expect(rows(json, 'cardAppearances'), hasLength(1));

        final target = openTestDatabase();
        addTearDown(target.close);
        final service = serviceFor(target);
        await service.restore(await service.read(backup), RestoreMode.replace);
        final look = await DriftCardAppearanceRepository(
          target,
          clock: FixedClock(DateTime.utc(2026)),
        ).get(seeded.haus);
        expect(look.background, CardColor.mint);
        expect(look.wordScale, 1.4);
        expect(look.sticker, CardSticker.star);
        expect(look.isHighlighted(HighlightField.meaning, 'منزل'), isTrue);
        expect(look.isHighlighted(HighlightField.word, 'Haus'), isTrue);
      },
    );

    test('an older backup (schema 3, no appearance list or count) still '
        'restores, with standard appearances', () async {
      final older = edited(backup, (f) {
        f['schemaVersion'] = 3;
        (f['data'] as Map<String, dynamic>).remove('cardAppearances');
        counts(f).remove('cardAppearances');
      });
      final target = openTestDatabase();
      addTearDown(target.close);
      final service = serviceFor(target);
      final v = await service.read(older);
      expect(v.snapshot.cardAppearances, isEmpty);
      await service.restore(v, RestoreMode.replace);
      expect(await target.select(target.cardAppearances).get(), isEmpty);
      expect(await target.select(target.vocabularyEntries).get(), hasLength(3));
    });

    test(
      'invalid appearance values are rejected before anything is written',
      () async {
        final cases = <String, void Function(Map<String, dynamic>)>{
          'colour': (f) => row(f, 'cardAppearances')['background'] = 'neon',
          'sticker': (f) => row(f, 'cardAppearances')['sticker'] = 'unicorn',
          'scale': (f) => row(f, 'cardAppearances')['wordScale'] = 9,
          'highlights': (f) =>
              row(f, 'cardAppearances')['highlights'] = '[{"f":"x","t":"a"}]',
          'not json': (f) => row(f, 'cardAppearances')['highlights'] = '[',
        };
        for (final MapEntry(:key, :value) in cases.entries) {
          await expectLater(
            serviceFor(source).read(edited(backup, value)),
            throwsA(
              isA<BackupException>().having(
                (e) => e.error,
                'error',
                BackupError.invalidValue,
              ),
            ),
            reason: key,
          );
        }
        await expectLater(
          serviceFor(source).read(
            edited(
              backup,
              (f) => row(f, 'cardAppearances')['entryId'] = 'nope',
            ),
          ),
          throwsA(
            isA<BackupException>().having(
              (e) => e.error,
              'error',
              BackupError.brokenReference,
            ),
          ),
        );
        await expectLater(
          serviceFor(source).read(
            edited(
              backup,
              (f) => rows(
                f,
                'cardAppearances',
              ).add(Map.of(row(f, 'cardAppearances'))),
            ),
          ),
          throwsA(
            isA<BackupException>().having(
              (e) => e.error,
              'error',
              BackupError.duplicateId,
            ),
          ),
        );
      },
    );

    test('merge brings the appearance of added words only; a word already '
        'on the device keeps its own look', () async {
      final target = openTestDatabase();
      addTearDown(target.close);
      final service = serviceFor(target);
      await service.restore(await service.read(backup), RestoreMode.merge);
      final looks = DriftCardAppearanceRepository(
        target,
        clock: FixedClock(DateTime.utc(2026)),
      );
      expect((await looks.get(seeded.haus)).background, CardColor.mint);
      await looks.save(
        seeded.haus,
        const CardAppearance(background: CardColor.sky),
      );

      final r = await service.restore(
        await service.read(backup),
        RestoreMode.merge,
      );
      expect(r.cardAppearancesAdded, 0);
      expect((await looks.get(seeded.haus)).background, CardColor.sky);
    });
  });

  group('FileSafetyBackupStore', () {
    test('keeps the newest three copies, newest first', () async {
      final dir = await Directory.systemTemp.createTemp('wortbox_safety');
      addTearDown(() => dir.delete(recursive: true));
      final store = FileSafetyBackupStore(baseDirectory: () async => dir);
      for (var i = 0; i < 5; i++) {
        await store.save(
          Uint8List.fromList([i]),
          DateTime.utc(2026, 10, 20, 12, i, 30, 5),
        );
      }
      final copies = await store.list();
      expect(copies.map((c) => c.savedAt), [
        DateTime.utc(2026, 10, 20, 12, 4, 30, 5),
        DateTime.utc(2026, 10, 20, 12, 3, 30, 5),
        DateTime.utc(2026, 10, 20, 12, 2, 30, 5),
      ]);
      expect(await copies.first.read(), [4]);
      expect(
        Directory('${dir.path}/safety_backups').listSync().whereType<File>(),
        hasLength(3),
      );
    });
  });
}
