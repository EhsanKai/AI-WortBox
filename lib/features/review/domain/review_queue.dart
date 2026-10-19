import 'package:flutter/foundation.dart';

import 'flashcard.dart';

/// A word that can be reviewed: it has at least one meaning.
@immutable
class QueueEntry {
  const QueueEntry({
    required this.entryId,
    required this.deckId,
    required this.createdAt,
  });

  final String entryId;
  final String deckId;

  /// UTC. New cards are introduced oldest word first.
  final DateTime createdAt;
}

/// One card due for review: a word asked in one direction.
@immutable
class DueCard {
  const DueCard({
    required this.entryId,
    required this.direction,
    required this.state,
  });

  final String entryId;
  final CardDirection direction;

  /// Current scheduling state; [ReviewState.isNew] for a card never answered
  /// in scheduled review (its `flashcards` row is created on first answer).
  final ReviewState state;

  @override
  bool operator ==(Object other) =>
      other is DueCard &&
      other.entryId == entryId &&
      other.direction == direction &&
      other.state == state;

  @override
  int get hashCode => Object.hash(entryId, direction, state);

  @override
  String toString() => 'DueCard($entryId, ${direction.name}, ${state.state})';
}

/// Selects the cards to review now.
///
/// - A card in (re)learning is due when its due time is at most
///   [learnAhead] away, so a forgotten word can return in the same session.
/// - A card in review is due when its due time falls before the end of the
///   learner's local day ([endOfTodayUtc]).
/// - A card never answered is new. New cards are introduced per deck up to
///   [newCardsLeft] (the deck's daily limit minus cards introduced today),
///   oldest word first, German → Persian before Persian → German.
/// - With both directions, a word is asked in one direction per day: a card
///   not yet answered today is left out when its sibling was answered today
///   ([startOfTodayUtc]) or is already in the queue.
///
/// Order: cards already being learned or reviewed (earliest due first),
/// then new cards. At most [limit] cards.
List<DueCard> buildDueQueue({
  required List<QueueEntry> entries,
  required Map<(String, CardDirection), ReviewState> cards,
  required Set<CardDirection> directions,
  required Map<String, int> newCardsLeft,
  required DateTime nowUtc,
  required DateTime startOfTodayUtc,
  required DateTime endOfTodayUtc,
  Duration learnAhead = const Duration(minutes: 20),
  int? limit,
}) {
  bool answeredToday(ReviewState? s) =>
      s?.lastReviewedAt != null &&
      !s!.lastReviewedAt!.isBefore(startOfTodayUtc);

  bool isDue(ReviewState s) => switch (s.state) {
    CardState.newCard => true,
    CardState.learning ||
    CardState.relearning => !s.due.isAfter(nowUtc.add(learnAhead)),
    CardState.review => s.due.isBefore(endOfTodayUtc),
  };

  final ordered = [
    for (final d in CardDirection.values)
      if (directions.contains(d)) d,
  ];
  final scheduled = <DueCard>[];
  final fresh = <(QueueEntry, DueCard)>[];
  for (final entry in entries) {
    final candidates = <DueCard>[];
    for (final direction in ordered) {
      final state = cards[(entry.entryId, direction)];
      final current = state ?? ReviewState.initial(nowUtc);
      if (!isDue(current)) continue;
      if (ordered.length > 1 && !answeredToday(state)) {
        final sibling = cards[(entry.entryId, _other(direction))];
        if (answeredToday(sibling)) continue;
      }
      candidates.add(
        DueCard(entryId: entry.entryId, direction: direction, state: current),
      );
    }
    if (candidates.isEmpty) continue;
    // Siblings: keep every card already answered today (it is in a
    // learning step), otherwise only the most urgent one.
    final today = candidates.where((c) => answeredToday(c.state)).toList();
    final chosen = today.isNotEmpty
        ? today
        : [
            (candidates..sort((a, b) {
                  if (a.state.isNew != b.state.isNew) {
                    return a.state.isNew ? 1 : -1;
                  }
                  final byDue = a.state.due.compareTo(b.state.due);
                  return byDue != 0
                      ? byDue
                      : a.direction.index.compareTo(b.direction.index);
                }))
                .first,
          ];
    for (final card in chosen) {
      if (card.state.isNew) {
        fresh.add((entry, card));
      } else {
        scheduled.add(card);
      }
    }
  }

  scheduled.sort((a, b) => a.state.due.compareTo(b.state.due));
  fresh.sort((a, b) {
    final byAge = a.$1.createdAt.compareTo(b.$1.createdAt);
    if (byAge != 0) return byAge;
    final byId = a.$1.entryId.compareTo(b.$1.entryId);
    return byId != 0 ? byId : a.$2.direction.index - b.$2.direction.index;
  });
  final left = Map.of(newCardsLeft);
  final introduced = <DueCard>[];
  for (final (entry, card) in fresh) {
    final remaining = left[entry.deckId] ?? 0;
    if (remaining <= 0) continue;
    left[entry.deckId] = remaining - 1;
    introduced.add(card);
  }
  final queue = [...scheduled, ...introduced];
  return limit == null || queue.length <= limit
      ? queue
      : queue.sublist(0, limit);
}

CardDirection _other(CardDirection d) =>
    d == CardDirection.forward ? CardDirection.reverse : CardDirection.forward;
