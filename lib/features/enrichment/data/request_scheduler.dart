import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/time/clock.dart';
import '../domain/enrichment.dart';
import 'ai_local_store.dart';

/// What the settings screen shows about request pacing.
@immutable
class RateLimitStatus {
  const RateLimitStatus({this.cooldownUntil, this.pausedUntil});

  /// OpenRouter asked to wait (rate limit) until then, UTC.
  final DateTime? cooldownUntil;

  /// Free requests are paused (daily quota) until then, UTC.
  final DateTime? pausedUntil;
}

/// Paces every request to OpenRouter, app-wide:
///
/// - at most [maxConcurrent] requests at a time (default 1);
/// - at least [minSpacing] between the starts of two requests;
/// - no request while OpenRouter's `Retry-After` / rate-limit reset is
///   pending ([coolDownUntil]): short waits are waited out, long ones fail
///   at once with `rateLimited`;
/// - in free mode, no request at all while the daily free quota is used up
///   (persisted, so a restart does not resume hammering).
///
/// This never works around account limits: it only waits or stops.
class RequestScheduler {
  RequestScheduler({
    required this._clock,
    Future<void> Function(Duration)? sleep,
    this.localState,
    this.maxConcurrent = AppConfig.aiMaxConcurrentRequests,
    this.minSpacing = AppConfig.aiMinRequestSpacing,
    this.maxWait = AppConfig.aiMaxRetryDelay,
  }) : _sleep = sleep ?? Future<void>.delayed;

  final Clock _clock;
  final Future<void> Function(Duration) _sleep;
  final AiLocalState? localState;
  final int maxConcurrent;
  final Duration minSpacing;
  final Duration maxWait;

  int _active = 0;
  final _waiting = Queue<Completer<void>>();
  DateTime? _lastStart;
  DateTime? _cooldownUntil;

  DateTime? get cooldownUntil {
    final until = _cooldownUntil;
    return until != null && _clock.nowUtc().isBefore(until) ? until : null;
  }

  Future<RateLimitStatus> status() async {
    final now = _clock.nowUtc();
    DateTime? paused;
    try {
      final usage = await localState?.readUsage();
      if (usage != null && usage.isPaused(now)) paused = usage.pausedUntil;
    } on StorageException {
      paused = null;
    }
    return RateLimitStatus(cooldownUntil: cooldownUntil, pausedUntil: paused);
  }

  /// No request starts before [utc] (keeps the later of two cooldowns).
  void coolDownUntil(DateTime utc) {
    final current = _cooldownUntil;
    if (current == null || utc.isAfter(current)) _cooldownUntil = utc.toUtc();
  }

  /// Pauses free requests until [utc] (the daily quota reset).
  Future<void> pauseFreeUntil(DateTime utc) async {
    try {
      await localState?.pauseUntil(utc);
    } on StorageException {
      // Still paused for this session.
    }
    coolDownUntil(utc);
  }

  /// Runs [send] when pacing allows. Throws `dailyQuotaExhausted` (free
  /// mode) or `rateLimited` without sending when it must not be sent now.
  Future<T> run<T>(
    Future<T> Function() send, {
    required bool free,
    EnrichmentCancellation? cancellation,
  }) async {
    await _acquire(cancellation);
    try {
      if (free) await _checkDailyPause();
      final cooldown = cooldownUntil;
      if (cooldown != null) {
        final wait = cooldown.difference(_clock.nowUtc());
        if (wait > maxWait) {
          throw EnrichmentException(
            EnrichmentError.rateLimited,
            retryAt: cooldown,
          );
        }
        await _wait(wait, cancellation);
      }
      if (_lastStart case final last?) {
        final wait = last.add(minSpacing).difference(_clock.nowUtc());
        if (wait > Duration.zero) await _wait(wait, cancellation);
      }
      _throwIfCancelled(cancellation);
      _lastStart = _clock.nowUtc();
      if (free) {
        try {
          await localState?.recordRequest();
        } on StorageException {
          // Counting is informational only.
        }
      }
      return await send();
    } finally {
      _release();
    }
  }

  Future<void> _checkDailyPause() async {
    AiUsage? usage;
    try {
      usage = await localState?.readUsage();
    } on StorageException {
      usage = null;
    }
    final now = _clock.nowUtc();
    if (usage != null && usage.isPaused(now)) {
      throw EnrichmentException(
        EnrichmentError.dailyQuotaExhausted,
        retryAt: usage.pausedUntil,
      );
    }
  }

  Future<void> _acquire(EnrichmentCancellation? cancellation) async {
    _throwIfCancelled(cancellation);
    if (_active < maxConcurrent) {
      _active++;
      return;
    }
    final turn = Completer<void>();
    _waiting.add(turn);
    try {
      await cancellable(turn.future, cancellation);
    } on EnrichmentException {
      // Give up the place in line; if the turn was already handed over,
      // pass it on.
      if (!_waiting.remove(turn)) _release();
      rethrow;
    }
  }

  void _release() {
    if (_waiting.isNotEmpty) {
      // The slot passes directly to the next waiter.
      _waiting.removeFirst().complete();
    } else {
      _active--;
    }
  }

  Future<void> _wait(Duration d, EnrichmentCancellation? cancellation) =>
      cancellable(_sleep(d), cancellation);

  static void _throwIfCancelled(EnrichmentCancellation? cancellation) {
    if (cancellation?.isCancelled ?? false) {
      throw const EnrichmentException(EnrichmentError.cancelled);
    }
  }
}

/// Completes with [future], or throws `cancelled` as soon as the user
/// cancels.
Future<T> cancellable<T>(
  Future<T> future,
  EnrichmentCancellation? cancellation,
) {
  if (cancellation == null) return future;
  if (cancellation.isCancelled) {
    return Future.error(const EnrichmentException(EnrichmentError.cancelled));
  }
  return Future.any([
    future,
    cancellation.whenCancelled.then<T>(
      (_) => throw const EnrichmentException(EnrichmentError.cancelled),
    ),
  ]);
}
