import 'package:ai_wortbox/app/app.dart';
import 'package:ai_wortbox/app/providers.dart';
import 'package:ai_wortbox/core/id/id_generator.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    // A typical phone viewport (390x844 logical pixels).
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(
            FixedClock(DateTime.utc(2026, 10, 15, 8)),
          ),
          idGeneratorProvider.overrideWithValue(SequentialIdGenerator()),
        ],
        // Keep failing providers from retrying on timers during tests.
        retry: (_, _) => null,
        child: const AiWortBoxApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Unmount the tree so Drift stream subscriptions are cancelled before the
  // database is closed.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  }

  testWidgets('launches in Persian, right-to-left, on the Today tab', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('AI WortBox'), findsWidgets);
    expect(find.text('مرور امروز'), findsWidgets);
    expect(find.text('هنوز دسته‌ای نساخته‌اید'), findsOneWidget);
    final direction = Directionality.of(
      tester.element(find.byType(Scaffold).first),
    );
    expect(direction, TextDirection.rtl);

    await unmount(tester);
  });

  testWidgets('shows all five primary destinations', (tester) async {
    await pumpApp(tester);
    for (final label in [
      'مرور امروز',
      'لغات من',
      'افزودن لغت',
      'آمار',
      'تنظیمات',
    ]) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }

    await tester.tap(find.text('افزودن لغت'));
    await tester.pumpAndSettle();
    expect(find.text('وارد کردن فایل CSV'), findsOneWidget);
    expect(find.text('افزودن دستی'), findsOneWidget);
    expect(find.text('اسکن صفحهٔ کتاب'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('creates a deck and shows it in My Words', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('لغات من'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('decks.create')));
    await tester.pumpAndSettle();

    // Defaults are visible in the form.
    expect(find.text('Deutsch ← فارسی'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('createDeck.name')),
      'Der Vorleser',
    );
    await tester.tap(find.byKey(const Key('createDeck.submit')));
    await tester.pumpAndSettle();

    expect(find.text('Der Vorleser'), findsOneWidget);
    expect(find.textContaining('بدون لغت'), findsOneWidget);
    expect(await db.select(db.decks).get(), hasLength(1));

    // Open the deck detail screen.
    await tester.tap(find.text('Der Vorleser'));
    await tester.pumpAndSettle();
    expect(find.textContaining('حداکثر ۲۰ کارت جدید در روز'), findsOneWidget);

    await unmount(tester);
  });

  testWidgets('shows validation errors for empty and duplicate names', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.ensureVisible(find.byKey(const Key('today.createDeck')));
    await tester.tap(find.byKey(const Key('today.createDeck')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('createDeck.submit')));
    await tester.pumpAndSettle();
    expect(find.text('نام دسته را وارد کنید.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('createDeck.name')), 'A1');
    await tester.tap(find.byKey(const Key('createDeck.submit')));
    await tester.pumpAndSettle();
    expect(find.text('دستهٔ «A1» ساخته شد.'), findsOneWidget);
    // Let the confirmation snackbar expire.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(find.text('لغات من'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('decks.create')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('createDeck.name')), 'a1');
    await tester.tap(find.byKey(const Key('createDeck.submit')));
    await tester.pumpAndSettle();
    expect(find.text('دسته‌ای با همین نام وجود دارد.'), findsOneWidget);
    expect(await db.select(db.decks).get(), hasLength(1));

    await unmount(tester);
  });
}
