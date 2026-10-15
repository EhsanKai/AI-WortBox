import 'package:flutter/foundation.dart';

/// Which side of a vocabulary entry is shown as the prompt.
///
/// Persisted by [name]; never rename existing values without a migration.
enum CardDirection {
  /// Source word (German) → meaning (Persian).
  forward,

  /// Meaning (Persian) → source word (German). Scheduled independently.
  reverse,
}

/// Scheduling phase of a card.
///
/// [newCard] means "never reviewed". The other values mirror FSRS states
/// (the `fsrs` package models learning=1, review=2, relearning=3).
///
/// Persisted by [name]; never rename existing values without a migration.
enum CardState { newCard, learning, review, relearning }

/// All scheduler state for one card. Kept separate from vocabulary content so
/// that editing a definition never resets review history.
@immutable
class ReviewState {
  const ReviewState({
    required this.state,
    required this.due,
    this.step,
    this.stability,
    this.difficulty,
    this.lastReviewedAt,
    this.reviewCount = 0,
    this.lapseCount = 0,
    this.schedulerVersion,
  });

  /// State of a card that has never been reviewed; due immediately.
  factory ReviewState.initial(DateTime nowUtc) =>
      ReviewState(state: CardState.newCard, due: nowUtc.toUtc());

  final CardState state;

  /// Current (re)learning step, or null in the review state.
  final int? step;

  /// FSRS memory stability; null until the first review.
  final double? stability;

  /// FSRS difficulty; null until the first review.
  final double? difficulty;

  /// UTC.
  final DateTime due;

  /// UTC.
  final DateTime? lastReviewedAt;

  final int reviewCount;
  final int lapseCount;

  /// Identifies the algorithm/parameters that produced this state
  /// (set from Phase 5 on), so state can be migrated if they change.
  final String? schedulerVersion;

  bool get isNew => state == CardState.newCard;

  @override
  bool operator ==(Object other) =>
      other is ReviewState &&
      other.state == state &&
      other.step == step &&
      other.stability == stability &&
      other.difficulty == difficulty &&
      other.due == due &&
      other.lastReviewedAt == lastReviewedAt &&
      other.reviewCount == reviewCount &&
      other.lapseCount == lapseCount &&
      other.schedulerVersion == schedulerVersion;

  @override
  int get hashCode => Object.hash(
    state,
    step,
    stability,
    difficulty,
    due,
    lastReviewedAt,
    reviewCount,
    lapseCount,
    schedulerVersion,
  );
}

/// A reviewable card for one direction of a vocabulary entry.
@immutable
class Flashcard {
  const Flashcard({
    required this.id,
    required this.entryId,
    required this.direction,
    required this.reviewState,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String entryId;
  final CardDirection direction;
  final ReviewState reviewState;

  /// UTC.
  final DateTime createdAt;

  /// UTC.
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      other is Flashcard &&
      other.id == id &&
      other.entryId == entryId &&
      other.direction == direction &&
      other.reviewState == reviewState &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode =>
      Object.hash(id, entryId, direction, reviewState, createdAt, updatedAt);
}
