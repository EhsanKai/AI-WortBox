import 'package:flutter/foundation.dart';

import 'review_event.dart';

/// The rule the Memory Coach uses to decide that a word needs extra
/// practice. A fixed, documented rule over the recorded review history; it
/// is not a prediction or a statistical model (see docs/decisions.md, D52).
///
/// For each word, the answers of the last [lookback] are taken, newest
/// first, at most [window] of them (both review directions together). The
/// word needs practice when
///
/// 1. "not remembered" answers in that window come from at least
///    [minFailedSessions] different review sessions, and
/// 2. its latest [recoveryStreak] answers are not all "remembered".
///
/// Rule 1 means one bad session (e.g. a brand-new word forgotten twice in
/// its first session) is not enough, and words without history never
/// qualify. Rule 2 means recent success outweighs older failures.
@immutable
class MemoryCoachRule {
  const MemoryCoachRule({
    this.lookback = const Duration(days: 30),
    this.window = 8,
    this.minFailedSessions = 2,
    this.recoveryStreak = 3,
  }) : assert(window > 0),
       assert(minFailedSessions > 0),
       assert(recoveryStreak > 0);

  static const standard = MemoryCoachRule();

  final Duration lookback;
  final int window;
  final int minFailedSessions;
  final int recoveryStreak;
}

/// A word the Memory Coach suggests practising, with the evidence.
@immutable
class StrugglingWord {
  const StrugglingWord({
    required this.entryId,
    required this.failures,
    required this.attempts,
    required this.lastFailedAt,
  });

  final String entryId;

  /// "Not remembered" answers within the rule's window.
  final int failures;

  /// Answers within the rule's window (at most `MemoryCoachRule.window`).
  final int attempts;

  /// UTC time of the most recent "not remembered" answer.
  final DateTime lastFailedAt;

  @override
  bool operator ==(Object other) =>
      other is StrugglingWord &&
      other.entryId == entryId &&
      other.failures == failures &&
      other.attempts == attempts &&
      other.lastFailedAt == lastFailedAt;

  @override
  int get hashCode => Object.hash(entryId, failures, attempts, lastFailedAt);

  @override
  String toString() => 'StrugglingWord($entryId, $failures/$attempts)';
}

/// The words in [events] that need practice at [now] under [rule], most
/// failures first, then the most recently failed (ties by entry id, so the
/// order is deterministic). Events of deleted words (no entry id) and
/// events outside the rule's lookback are ignored. Reads only; nothing is
/// written.
List<StrugglingWord> findStrugglingWords(
  Iterable<ReviewEvent> events, {
  required DateTime now,
  MemoryCoachRule rule = MemoryCoachRule.standard,
}) {
  final since = now.subtract(rule.lookback);
  final byEntry = <String, List<ReviewEvent>>{};
  for (final event in events) {
    final id = event.entryId;
    if (id == null || event.reviewedAt.isBefore(since)) continue;
    (byEntry[id] ??= []).add(event);
  }

  final result = <StrugglingWord>[];
  for (final MapEntry(key: id, value: all) in byEntry.entries) {
    all.sort((a, b) {
      final byTime = b.reviewedAt.compareTo(a.reviewedAt);
      return byTime != 0 ? byTime : b.id.compareTo(a.id);
    });
    final recent = all.take(rule.window).toList();
    final failed = [
      for (final e in recent)
        if (e.outcome == ReviewOutcome.forgotten) e,
    ];
    final failedSessions = {for (final e in failed) e.sessionId};
    if (failedSessions.length < rule.minFailedSessions) continue;
    final latest = recent.take(rule.recoveryStreak);
    final recovered =
        latest.length >= rule.recoveryStreak &&
        latest.every((e) => e.outcome == ReviewOutcome.remembered);
    if (recovered) continue;
    result.add(
      StrugglingWord(
        entryId: id,
        failures: failed.length,
        attempts: recent.length,
        lastFailedAt: failed.first.reviewedAt,
      ),
    );
  }
  result.sort((a, b) {
    final byFailures = b.failures.compareTo(a.failures);
    if (byFailures != 0) return byFailures;
    final byTime = b.lastFailedAt.compareTo(a.lastFailedAt);
    return byTime != 0 ? byTime : a.entryId.compareTo(b.entryId);
  });
  return result;
}
