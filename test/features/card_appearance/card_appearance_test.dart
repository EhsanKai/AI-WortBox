import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/card_appearance/data/drift_card_appearance_repository.dart';
import 'package:ai_wortbox/features/card_appearance/domain/card_appearance.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/learning_data.dart';
import '../../helpers/test_database.dart';

void main() {
  group('CardAppearance', () {
    test('standard by default', () {
      expect(const CardAppearance().isStandard, isTrue);
      expect(
        const CardAppearance(sticker: CardSticker.star).isStandard,
        isFalse,
      );
    });

    test('highlights compare case-, space- and letter-variant-insensitively '
        'and toggle on and off', () {
      var a = CardAppearance.standard
          .toggleHighlight(HighlightField.word, 'Haus,')
          .toggleHighlight(HighlightField.meaning, 'خانه‌ي من');
      expect(a.isHighlighted(HighlightField.word, 'haus'), isTrue);
      // Arabic YEH vs Persian YEH, ZWNJ kept in the stored text.
      expect(a.isHighlighted(HighlightField.meaning, 'خانه‌ی من'), isTrue);
      expect(a.isHighlighted(HighlightField.meaning, 'Haus'), isFalse);
      a = a.toggleHighlight(HighlightField.word, 'HAUS');
      expect(a.isHighlighted(HighlightField.word, 'Haus'), isFalse);
    });

    test('stored highlights round-trip, keeping German and Persian text', () {
      final a = CardAppearance(
        highlights: {
          const CardHighlight(HighlightField.word, 'Bärenhöhle'),
          const CardHighlight(HighlightField.meaning, 'غارِ خرس'),
        },
      );
      expect(CardAppearance.parseHighlights(a.highlightsJson), a.highlights);
      expect(
        CardAppearance.parseHighlights('[{"f":"x"}, 3, {"f":"word","t":" "}]'),
        isEmpty,
      );
      expect(CardAppearance.parseHighlights('not json'), isEmpty);
    });

    test('sizes are kept within the allowed range', () {
      expect(CardAppearance.standard.copyWith(wordScale: 9).wordScale, 1.6);
      expect(
        CardAppearance.standard.copyWith(meaningScale: 0.1).meaningScale,
        0.85,
      );
      expect(CardAppearance.clampScale(double.nan), 1);
    });
  });

  group('DriftCardAppearanceRepository', () {
    late AppDatabase db;
    late SeededIds ids;
    late DriftCardAppearanceRepository repo;

    setUp(() async {
      db = openTestDatabase();
      ids = await seedLearningData(db);
      repo = DriftCardAppearanceRepository(
        db,
        clock: FixedClock(DateTime.utc(2026, 10, 21)),
      );
    });
    tearDown(() => db.close());

    test('a word without a stored appearance (e.g. from an older version) '
        'looks standard', () async {
      expect(await repo.get(ids.gehen), CardAppearance.standard);
      expect(await repo.watch(ids.gehen).first, CardAppearance.standard);
    });

    test('saves and reloads every setting; cards are independent', () async {
      final look = CardAppearance(
        background: CardColor.lavender,
        ink: CardInk.plum,
        wordScale: 1.6,
        meaningScale: 0.85,
        highlightColor: HighlightColor.blue,
        highlights: {const CardHighlight(HighlightField.word, 'gehen')},
        sticker: CardSticker.germany,
      );
      await repo.save(ids.gehen, look);
      expect(await repo.get(ids.gehen), look);
      // The seeded Haus card keeps its own look.
      expect((await repo.get(ids.haus)).background, CardColor.mint);

      await repo.save(
        ids.gehen,
        look.copyWith(sticker: () => CardSticker.bulb),
      );
      expect((await repo.get(ids.gehen)).sticker, CardSticker.bulb);
      await repo.save(ids.gehen, look.copyWith(sticker: () => null));
      expect((await repo.get(ids.gehen)).sticker, isNull);
    });

    test('saving the standard look (reset) removes the stored row', () async {
      await repo.save(ids.haus, CardAppearance.standard);
      expect(
        await (db.select(
          db.cardAppearances,
        )..where((t) => t.entryId.equals(ids.haus))).get(),
        isEmpty,
      );
      expect(await repo.get(ids.haus), CardAppearance.standard);
    });

    test('styling never changes the word, its FSRS state, review history '
        'or statistics', () async {
      final before = await dumpLearningData(db);
      await repo.save(
        ids.haus,
        const CardAppearance(background: CardColor.rose, wordScale: 1.2),
      );
      await repo.save(
        ids.gehen,
        const CardAppearance(sticker: CardSticker.pin),
      );
      final after = await dumpLearningData(db);
      for (final table in before.keys) {
        if (table == 'card_appearances') continue;
        expect(after[table], before[table], reason: table);
      }
    });

    test('unknown or out-of-range stored values read as the default', () async {
      await db.customStatement(
        'INSERT OR REPLACE INTO card_appearances (entry_id, background, ink, '
        'word_scale, meaning_scale, highlight_color, highlights, sticker, '
        "updated_at) VALUES ('${ids.gehen}', 'neon', 'gold', 7, -1, 'x', "
        "'{bad', 'unicorn', '2026-10-21T00:00:00.000Z')",
      );
      final look = await repo.get(ids.gehen);
      expect(look.background, CardColor.standard);
      expect(look.ink, CardInk.standard);
      expect(look.wordScale, 1.6);
      expect(look.meaningScale, 0.85);
      expect(look.highlights, isEmpty);
      expect(look.sticker, isNull);
    });

    test('deleting a word deletes its appearance', () async {
      await DriftVocabularyRepository(
        db,
        clock: FixedClock(DateTime.utc(2026, 10, 21)),
        ids: SequentialIdGenerator('x'),
      ).deleteEntry(ids.haus);
      expect(await db.select(db.cardAppearances).get(), isEmpty);
    });
  });
}
