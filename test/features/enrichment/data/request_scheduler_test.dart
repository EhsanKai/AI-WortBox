import 'dart:async';

import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/time/clock.dart';
import 'package:ai_wortbox/features/enrichment/data/ai_local_store.dart';
import 'package:ai_wortbox/features/enrichment/data/request_scheduler.dart';
import 'package:ai_wortbox/features/enrichment/domain/enrichment.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/ai_fakes.dart';

void main() {
  late FixedClock clock;
  late List<Duration> sleeps;
  late AiLocalState local;
  late RequestScheduler scheduler;

  setUp(() {
    clock = FixedClock(DateTime.utc(2026, 10, 19, 9));
    sleeps = [];
    local = AiLocalState(InMemoryAiKeyValueStore(), clock: clock);
    scheduler = RequestScheduler(
      clock: clock,
      localState: local,
      sleep: (d) async {
        sleeps.add(d);
        clock.advance(d);
      },
    );
  });

  test('requests start at least 4 seconds apart', () async {
    await scheduler.run(() async => 1, free: true);
    clock.advance(const Duration(seconds: 1));
    await scheduler.run(() async => 2, free: true);
    clock.advance(const Duration(seconds: 10));
    await scheduler.run(() async => 3, free: true);
    expect(sleeps, [const Duration(seconds: 3)]);
    expect((await local.readUsage()).requestsToday, 3);
  });

  test('only one request runs at a time (default concurrency 1)', () async {
    var running = 0;
    var maxRunning = 0;
    final gates = [Completer<void>(), Completer<void>(), Completer<void>()];
    Future<int> task(int i) async {
      running++;
      maxRunning = running > maxRunning ? running : maxRunning;
      await gates[i].future;
      running--;
      return i;
    }

    final all = Future.wait([
      for (var i = 0; i < 3; i++) scheduler.run(() => task(i), free: false),
    ]);
    for (final g in gates) {
      await Future<void>.delayed(Duration.zero);
      g.complete();
    }
    expect(await all, [0, 1, 2]);
    expect(maxRunning, 1);
  });

  test(
    'a short cooldown is waited out; a long one fails without sending',
    () async {
      scheduler.coolDownUntil(clock.nowUtc().add(const Duration(seconds: 5)));
      await scheduler.run(() async => 1, free: true);
      expect(sleeps.first, const Duration(seconds: 5));

      final until = clock.nowUtc().add(const Duration(minutes: 5));
      scheduler.coolDownUntil(until);
      var sent = false;
      await expectLater(
        scheduler.run(() async => sent = true, free: true),
        throwsA(
          isA<EnrichmentException>()
              .having((e) => e.error, 'error', EnrichmentError.rateLimited)
              .having((e) => e.retryAt, 'retryAt', until),
        ),
      );
      expect(sent, isFalse);
      expect((await scheduler.status()).cooldownUntil, until);
    },
  );

  test('a persisted daily pause blocks free requests only', () async {
    final midnight = DateTime.utc(2026, 10, 20);
    await scheduler.pauseFreeUntil(midnight);
    var sent = 0;
    await expectLater(
      RequestScheduler(
        clock: clock,
        localState: local,
      ).run(() async => sent++, free: true),
      throwsA(
        isA<EnrichmentException>().having(
          (e) => e.error,
          'error',
          EnrichmentError.dailyQuotaExhausted,
        ),
      ),
    );
    expect(sent, 0);
    expect((await scheduler.status()).pausedUntil, midnight);
    // Paid requests (free-only off) are not subject to the free quota.
    await RequestScheduler(
      clock: clock,
      localState: local,
    ).run(() async => sent++, free: false);
    expect(sent, 1);
  });

  test('cancelling while waiting sends nothing and frees the slot', () async {
    final never = Completer<void>();
    final blocking = scheduler.run(() => never.future, free: false);
    final cancellation = EnrichmentCancellation();
    var sent = false;
    final waiting = scheduler.run(
      () async => sent = true,
      free: false,
      cancellation: cancellation,
    );
    await Future<void>.delayed(Duration.zero);
    cancellation.cancel();
    await expectLater(
      waiting,
      throwsA(
        isA<EnrichmentException>().having(
          (e) => e.error,
          'error',
          EnrichmentError.cancelled,
        ),
      ),
    );
    never.complete();
    await blocking;
    expect(sent, isFalse);
    expect(await scheduler.run(() async => 'next', free: false), 'next');
  });
}
