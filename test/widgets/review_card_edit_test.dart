import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:ai_wortbox/features/decks/data/drift_deck_repository.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:ai_wortbox/features/review/data/drift_study_repository.dart';
import 'package:ai_wortbox/features/review/domain/flashcard.dart';
import 'package:ai_wortbox/features/review/domain/review_direction.dart';
import 'package:ai_wortbox/features/review/domain/review_event.dart';
import 'package:ai_wortbox/features/tags/data/drift_tag_repository.dart';
import 'package:ai_wortbox/features/vocabulary/data/drift_vocabulary_repository.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/phase5_fakes.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late Deck deck;
  late DriftVocabularyRepository vocab;
  late VocabularyEntry haus;
  // The card was answered yesterday; it is due again now.
  final yesterday = FixedClock(DateTime.utc(2026, 10, 18, 8));
  final clock = FixedClock(DateTime.utc(2026, 10, 19, 8));

  const example = 'Das Haus steht am Ende der Straße.';
  const translation = 'خانه در انتهای خیابان است.';

  setUp(() async {
    db = openTestDatabase();
    deck = await DriftDeckRepository(
      db,
      clock: yesterday,
      ids: SequentialIdGenerator('deck'),
    ).createDeck(const DeckDraft(name: 'Kafka'));
    vocab = DriftVocabularyRepository(
      db,
      clock: yesterday,
      ids: SequentialIdGenerator('seed'),
    );
    haus = await vocab.createEntry(
      VocabularyDraft(
        deckId: deck.id,
        original: 'das Haus',
        meanings: const [
          VocabularyMeaning('خانه', explanation: 'ساختمان مسکونی'),
        ],
        lemma: 'Haus',
        partOfSpeech: 'Nomen',
        grammarInfo: 'das, die Häuser',
        exampleSentence: example,
        exampleTranslation: translation,
        notes: 'با «Heim» اشتباه نشود',
        sourceContext: 'Wir kaufen das Haus.',
      ),
    );
    await DriftTagRepository(
          db,
          clock: yesterday,
          ids: SequentialIdGenerator('tag'),
        )
        .createTag('A1')
        .then(
          (tag) => DriftTagRepository(
            db,
            clock: yesterday,
            ids: SequentialIdGenerator('tag2'),
          ).setEntryTags(haus.id, {tag.id}),
        );
    await DriftStudyRepository(
      db,
      clock: yesterday,
      ids: SequentialIdGenerator('study'),
    ).recordAnswer(
      entryId: haus.id,
      direction: CardDirection.forward,
      sessionId: 'yesterday',
      outcome: ReviewOutcome.remembered,
    );
  });
  tearDown(() => db.close());

  Future<void> startReview(
    WidgetTester tester, {
    FakeSpeechService? speech,
  }) async {
    await pumpApp(
      tester,
      db,
      initialLocation: '/today',
      clock: clock,
      speech: speech,
    );
    await tester.tap(find.byKey(const Key('today.startReview')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('practice.word')), findsOneWidget);
  }

  Future<void> reveal(WidgetTester tester) =>
      scrollAndTap(tester, find.byKey(const Key('practice.reveal')));

  String textOf(WidgetTester tester, String key) => tester
      .widget<Text>(
        find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text)),
      )
      .data!;

  TextDirection? directionOf(WidgetTester tester, String key) => tester
      .widget<Text>(
        find.descendant(of: find.byKey(Key(key)), matching: find.byType(Text)),
      )
      .textDirection;

  const detailKeys = [
    'practice.example',
    'practice.exampleTranslation',
    'practice.notes',
    'practice.grammar',
    'practice.lemma',
    'practice.source',
    'practice.tags',
    'practice.edit',
  ];

  testWidgets('the answer stays hidden until revealed; then everything '
      'stored is shown, including the German and the Persian example', (
    tester,
  ) async {
    await startReview(tester);
    for (final key in [...detailKeys, 'practice.meaning']) {
      expect(find.byKey(Key(key)), findsNothing, reason: key);
    }
    expect(find.text(example), findsNothing);
    expect(find.text(translation), findsNothing);

    await reveal(tester);
    for (final key in detailKeys) {
      await scrollTo(tester, find.byKey(Key(key)));
      expect(find.byKey(Key(key)), findsOneWidget, reason: key);
    }
    expect(textOf(tester, 'practice.example'), example);
    expect(textOf(tester, 'practice.exampleTranslation'), translation);
    expect(textOf(tester, 'practice.grammar'), 'Nomen · das, die Häuser');
    expect(textOf(tester, 'practice.notes'), 'با «Heim» اشتباه نشود');
    expect(textOf(tester, 'practice.source'), 'Wir kaufen das Haus.');
    expect(find.text('ساختمان مسکونی'), findsOneWidget);
    expect(find.textContaining('A1'), findsOneWidget);
    // German left-to-right, Persian right-to-left.
    expect(directionOf(tester, 'practice.example'), TextDirection.ltr);
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const Key('practice.exampleTranslation')),
              matching: find.byType(Text),
            ),
          )
          .textDirection,
      TextDirection.rtl,
    );
    await unmountApp(tester);
  });

  testWidgets('Persian → German also shows both examples after the reveal', (
    tester,
  ) async {
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            key: ReviewDirection.settingsKey,
            value: ReviewDirection.persianToGerman.name,
          ),
        );
    await pumpApp(
      tester,
      db,
      initialLocation: '/today/practice/session?free=1',
      clock: clock,
    );
    expect(find.byKey(const Key('practice.meaning')), findsOneWidget);
    expect(find.text('das Haus'), findsNothing);
    expect(find.text(example), findsNothing);
    await reveal(tester);
    expect(find.text('das Haus'), findsOneWidget);
    await scrollTo(
      tester,
      find.byKey(const Key('practice.exampleTranslation')),
    );
    expect(textOf(tester, 'practice.example'), example);
    expect(textOf(tester, 'practice.exampleTranslation'), translation);
    await unmountApp(tester);
  });

  testWidgets('edit from the card: saved values show at once on the same '
      'card, scheduling and history are unchanged, nothing is recorded; '
      'the edit is still there after a restart', (tester) async {
    final speech = FakeSpeechService();
    final cardBefore = (await db.select(db.flashcards).get()).single;
    expect(await db.select(db.reviewEvents).get(), hasLength(1));

    await startReview(tester, speech: speech);
    await reveal(tester);
    await scrollAndTap(tester, find.byKey(const Key('practice.edit')));
    expect(find.byKey(const Key('entryForm.word')), findsOneWidget);
    expect(find.byKey(const Key('practice.answer')), findsNothing);

    await tester.enterText(find.byKey(const Key('entryForm.word')), 'das Heim');
    await tester.enterText(
      find.byKey(const Key('entryForm.meaning.0')),
      'منزل',
    );
    await scrollTo(tester, find.byKey(const Key('entryForm.example')));
    await tester.enterText(
      find.byKey(const Key('entryForm.example')),
      'Das Heim ist warm.',
    );
    await tester.enterText(
      find.byKey(const Key('entryForm.exampleTranslation')),
      'منزل گرم است.',
    );
    await scrollAndTap(tester, find.byKey(const Key('entryForm.save')));

    // Back on the same card, still revealed, with the new content.
    expect(find.byKey(const Key('entryForm.word')), findsNothing);
    expect(find.byKey(const Key('practice.answer')), findsOneWidget);
    expect(find.text('۱ از ۱'), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('practice.word')));
    expect(textOf(tester, 'practice.word'), 'das Heim');
    expect(find.text('منزل'), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('practice.example')));
    expect(textOf(tester, 'practice.example'), 'Das Heim ist warm.');
    expect(textOf(tester, 'practice.exampleTranslation'), 'منزل گرم است.');
    // Pronunciation uses the corrected word.
    await scrollTo(tester, find.byKey(const Key('practice.word')));
    await tester.tap(find.byTooltip('تلفظ لغت').first);
    await tester.pumpAndSettle();
    expect(speech.spoken.last, ('das Heim', Language.german));

    // Saved through the repository (search key and normalized form too);
    // scheduling state and history untouched; no answer recorded.
    final row = (await db.select(db.vocabularyEntries).get()).single;
    expect(row.original, 'das Heim');
    expect(row.normalized, isNot(haus.normalized));
    expect(row.searchKey, contains('heim'));
    final cardAfter = (await db.select(db.flashcards).get()).single;
    expect(cardAfter, cardBefore);
    expect(await db.select(db.reviewEvents).get(), hasLength(1));

    // Answering afterwards records exactly one answer for this card.
    await scrollAndTap(tester, find.byKey(const Key('practice.remembered')));
    expect(find.byKey(const Key('practice.summary')), findsOneWidget);
    final events = await db.select(db.reviewEvents).get();
    expect(events, hasLength(2));
    expect(events.where((e) => e.sessionId != 'yesterday'), hasLength(1));
    await unmountApp(tester);

    // "Restart": the edit persists.
    await pumpApp(
      tester,
      db,
      initialLocation: '/words/decks/${deck.id}/entries/${haus.id}',
      clock: clock,
    );
    expect(find.text('das Heim'), findsOneWidget);
    await scrollTo(tester, find.text('Das Heim ist warm.'));
    expect(find.text('Das Heim ist warm.'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('cancelling an edit changes nothing and returns to the card', (
    tester,
  ) async {
    final rowBefore = (await db.select(db.vocabularyEntries).get()).single;
    final cardBefore = (await db.select(db.flashcards).get()).single;
    await startReview(tester);
    await reveal(tester);
    await scrollAndTap(tester, find.byKey(const Key('practice.edit')));
    await tester.enterText(find.byKey(const Key('entryForm.word')), 'falsch');
    // The editor's back button (no save).
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('practice.answer')), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('practice.word')));
    expect(textOf(tester, 'practice.word'), 'das Haus');
    expect((await db.select(db.vocabularyEntries).get()).single, rowBefore);
    expect((await db.select(db.flashcards).get()).single, cardBefore);
    expect(await db.select(db.reviewEvents).get(), hasLength(1));
    await unmountApp(tester);
  });

  testWidgets('missing optional fields are left out without placeholders', (
    tester,
  ) async {
    await vocab.deleteEntry(haus.id);
    await vocab.createEntry(
      VocabularyDraft(
        deckId: deck.id,
        original: 'der Baum',
        meanings: const [VocabularyMeaning('درخت')],
      ),
    );
    await pumpApp(
      tester,
      db,
      initialLocation: '/today/practice/session?free=1',
      clock: clock,
    );
    await reveal(tester);
    expect(find.text('درخت'), findsOneWidget);
    for (final key in detailKeys.where((k) => k != 'practice.edit')) {
      expect(find.byKey(Key(key)), findsNothing, reason: key);
    }
    expect(find.text('مثال'), findsNothing);
    expect(find.byKey(const Key('practice.edit')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('long content fits at 320 px with 2x text', (tester) async {
    await vocab.updateEntry(
      haus.id,
      VocabularyDraft(
        deckId: deck.id,
        original: 'das Haus am Ende der langen Straße hinter dem Bahnhof',
        meanings: [VocabularyMeaning('خانه ' * 12)],
        exampleSentence: 'Das ist ein sehr langer Beispielsatz. ' * 4,
        exampleTranslation: 'این یک جملهٔ مثال بسیار طولانی است. ' * 4,
        notes: 'یادداشت طولانی ' * 15,
        grammarInfo: 'das, die Häuser',
      ),
    );
    await pumpApp(
      tester,
      db,
      initialLocation: '/today/practice/session?free=1',
      clock: clock,
      size: const Size(320, 640),
      textScale: 2,
    );
    await reveal(tester);
    expect(tester.takeException(), isNull);
    await scrollAndTap(tester, find.byKey(const Key('practice.edit')));
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('entryForm.word')), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('practice.answer')), findsOneWidget);
    expect(find.byKey(const ValueKey(('practice.card', 0))), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('practice.remembered')));

    expect(tester.takeException(), isNull);
    await unmountApp(tester);
  });

  testWidgets('mark and unmark as difficult from the revealed card; no '
      'answer is recorded and scheduling is unchanged', (tester) async {
    final cardBefore = (await db.select(db.flashcards).get()).single;
    Future<DateTime?> mark() async =>
        (await db.select(db.vocabularyEntries).get()).single.markedDifficultAt;
    await startReview(tester);
    expect(find.byKey(const Key('practice.difficult')), findsNothing);
    await reveal(tester);

    await scrollAndTap(tester, find.byKey(const Key('practice.difficult')));
    expect(await mark(), isNotNull);
    expect(find.text('برداشتن علامت دشوار'), findsOneWidget);
    await scrollAndTap(tester, find.byKey(const Key('practice.difficult')));
    expect(await mark(), isNull);
    expect(find.text('علامت‌گذاری به‌عنوان دشوار'), findsOneWidget);

    expect(find.byKey(const Key('practice.answer')), findsOneWidget);
    expect((await db.select(db.flashcards).get()).single, cardBefore);
    expect(await db.select(db.reviewEvents).get(), hasLength(1));
    await unmountApp(tester);
  });

  testWidgets('add and remove tags from the revealed card; no answer is '
      'recorded and scheduling is unchanged', (tester) async {
    final cardBefore = (await db.select(db.flashcards).get()).single;
    final a1 = (await db.select(db.tags).get()).single;
    await startReview(tester);
    expect(find.byKey(const Key('practice.tags.edit')), findsNothing);
    await reveal(tester);

    await scrollAndTap(tester, find.byKey(const Key('practice.tags.edit')));
    // Remove A1, create and add B1.
    await tester.tap(find.byKey(Key('entryTags.${a1.id}')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('entryTags.newName')), 'B1');
    await tester.tap(find.byKey(const Key('entryTags.create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('entryTags.save')));
    await tester.pumpAndSettle();

    final assigned = await db.select(db.entryTags).get();
    final names = {
      for (final t in await db.select(db.tags).get())
        if (assigned.any((a) => a.tagId == t.id)) t.name,
    };
    expect(names, {'B1'});
    await scrollTo(tester, find.byKey(const Key('practice.tags')));
    expect(
      find.descendant(
        of: find.byKey(const Key('practice.tags')),
        matching: find.textContaining('B1'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('A1'), findsNothing);

    // Removing the last tag hides the tag section.
    await scrollAndTap(tester, find.byKey(const Key('practice.tags.edit')));
    final b1 = (await db.select(db.tags).get()).firstWhere(
      (t) => t.name == 'B1',
    );
    await tester.tap(find.byKey(Key('entryTags.${b1.id}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('entryTags.save')));
    await tester.pumpAndSettle();
    expect(await db.select(db.entryTags).get(), isEmpty);
    expect(find.byKey(const Key('practice.tags')), findsNothing);

    expect(find.byKey(const Key('practice.answer')), findsOneWidget);
    expect((await db.select(db.flashcards).get()).single, cardBefore);
    expect(await db.select(db.reviewEvents).get(), hasLength(1));
    await unmountApp(tester);
  });

  testWidgets('the counter does not grow when a forgotten card comes back '
      'for its learning step', (tester) async {
    await vocab.createEntry(
      VocabularyDraft(
        deckId: deck.id,
        original: 'der Baum',
        meanings: const [VocabularyMeaning('درخت')],
      ),
    );
    await startReview(tester);
    expect(find.text('۱ از ۲'), findsOneWidget);
    await reveal(tester);
    await scrollAndTap(tester, find.byKey(const Key('practice.forgotten')));
    expect(find.text('۲ از ۲'), findsOneWidget);
    expect(find.byKey(const Key('practice.repeat')), findsNothing);
    await reveal(tester);
    await scrollAndTap(tester, find.byKey(const Key('practice.remembered')));
    // The forgotten card again: same total, marked as a repeat.
    expect(find.text('۲ از ۲'), findsOneWidget);
    expect(find.text('۲ از ۳'), findsNothing);
    expect(find.text('۳ از ۳'), findsNothing);
    expect(find.byKey(const Key('practice.repeat')), findsOneWidget);
    await unmountApp(tester);
  });
}
