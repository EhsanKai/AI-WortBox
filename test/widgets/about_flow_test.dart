import 'package:ai_wortbox/data/database/app_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = openTestDatabase());
  tearDown(() => db.close());

  testWidgets('Settings → About shows the installed version, build and '
      'this build\'s changes (Persian, RTL)', (tester) async {
    await pumpApp(tester, db, initialLocation: '/settings');

    final tile = find.byKey(const Key('settings.about'));
    await scrollTo(tester, tile);
    expect(
      find.descendant(of: tile, matching: find.text('نسخهٔ 1.0.0 · ساخت 3')),
      findsOneWidget,
    );
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text('درباره برنامه'), findsWidgets);
    expect(
      find.descendant(
        of: find.byKey(const Key('about.version')),
        matching: find.text('1.0.0'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('about.build')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('about.installedNote')), findsOneWidget);
    expect(find.byKey(const Key('about.date')), findsOneWidget);
    expect(find.text('در مقایسه با ساخت 2'), findsOneWidget);
    expect(find.textContaining('پشتیبان‌گیری کامل'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(const Key('about.build')))),
      TextDirection.rtl,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('English layout is left-to-right with English notes', (
    tester,
  ) async {
    await pumpApp(
      tester,
      db,
      initialLocation: '/settings/about',
      locale: const Locale('en'),
    );

    expect(find.text('About AI WortBox'), findsWidgets);
    expect(find.text('Compared with build 2'), findsOneWidget);
    expect(find.textContaining('Full backup and restore'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(const Key('about.build')))),
      TextDirection.ltr,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a build without notes says so instead of showing other notes', (
    tester,
  ) async {
    await pumpApp(
      tester,
      db,
      initialLocation: '/settings/about',
      appInfo: FakeAppInfoSource(buildNumber: '99'),
    );

    expect(
      find.descendant(
        of: find.byKey(const Key('about.build')),
        matching: find.text('99'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('about.noNotes')), findsOneWidget);
    expect(find.byKey(const Key('about.currentNotes')), findsNothing);
    expect(find.byKey(const Key('about.date')), findsNothing);
  });
}
