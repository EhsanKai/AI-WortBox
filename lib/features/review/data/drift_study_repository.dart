import 'package:drift/drift.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/id/id_generator.dart';
import '../../../core/time/clock.dart';
import '../../../data/database/app_database.dart';
import '../domain/flashcard.dart';
import '../domain/review_event.dart';
import '../domain/review_queue.dart';
import '../domain/review_scheduler.dart';
import '../domain/study_repository.dart';

class DriftStudyRepository implements StudyRepository {
  DriftStudyRepository(
    this._db, {
    required this._clock,
    required this._ids,
    FsrsReviewScheduler? scheduler,
  }) : _scheduler = scheduler ?? FsrsReviewScheduler();

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;
  final FsrsReviewScheduler _scheduler;

  @override
  Future<List<DueCard>> dueQueue({
    String? deckId,
    required Set<CardDirection> directions,
    int? limit,
  }) => _guard('dueQueue', () => _queue(deckId, directions, limit));

  @override
  Stream<int> watchDueCount({
    String? deckId,
    required Set<CardDirection> directions,
  }) => _db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          _db.decks,
          _db.vocabularyEntries,
          _db.vocabularyMeanings,
          _db.flashcards,
        },
      )
      .watch()
      .asyncMap(
        (_) async =>
            (await dueQueue(deckId: deckId, directions: directions)).length,
      );

  Future<List<DueCard>> _queue(
    String? deckId,
    Set<CardDirection> directions,
    int? limit,
  ) async {
    if (directions.isEmpty) return const [];
    final now = _clock.nowUtc();
    final startOfToday = _startOfLocalDay(now);
    final endOfToday = startOfToday.add(const Duration(days: 1));

    final e = _db.vocabularyEntries;
    final hasMeaning = existsQuery(
      _db.selectOnly(_db.vocabularyMeanings)
        ..addColumns([_db.vocabularyMeanings.id])
        ..where(_db.vocabularyMeanings.entryId.equalsExp(e.id)),
    );
    final entryQuery = _db.selectOnly(e)
      ..addColumns([e.id, e.deckId, e.createdAt])
      ..where(
        hasMeaning &
            (deckId == null ? const Constant(true) : e.deckId.equals(deckId)),
      );
    final entries = [
      for (final row in await entryQuery.get())
        QueueEntry(
          entryId: row.read(e.id)!,
          deckId: row.read(e.deckId)!,
          createdAt: row.read(e.createdAt)!,
        ),
    ];
    if (entries.isEmpty) return const [];

    final f = _db.flashcards;
    final cardQuery = _db.select(f).join([
      innerJoin(e, e.id.equalsExp(f.entryId)),
    ])..where(deckId == null ? const Constant(true) : e.deckId.equals(deckId));
    final cards = <(String, CardDirection), ReviewState>{};
    final introducedToday = <String, int>{};
    for (final row in await cardQuery.get()) {
      final card = row.readTable(f);
      cards[(card.entryId, card.direction)] = _stateOf(card);
      // A row is created by the first scheduled answer, so its creation
      // time is when the card was introduced.
      if (!card.createdAt.isBefore(startOfToday)) {
        final deck = row.readTable(e).deckId;
        introducedToday[deck] = (introducedToday[deck] ?? 0) + 1;
      }
    }

    final deckQuery = _db.select(_db.decks);
    if (deckId != null) deckQuery.where((d) => d.id.equals(deckId));
    final newCardsLeft = {
      for (final deck in await deckQuery.get())
        deck.id: deck.dailyNewCardLimit - (introducedToday[deck.id] ?? 0),
    };

    return buildDueQueue(
      entries: entries,
      cards: cards,
      directions: directions,
      newCardsLeft: newCardsLeft,
      nowUtc: now,
      startOfTodayUtc: startOfToday,
      endOfTodayUtc: endOfToday,
      learnAhead: AppConfig.reviewLearnAhead,
      limit: limit,
    );
  }

  @override
  Future<(ReviewState, ReviewEvent)> recordAnswer({
    required String entryId,
    required CardDirection direction,
    required String sessionId,
    required ReviewOutcome outcome,
  }) => _guard('recordAnswer', () {
    return _db.transaction(() async {
      final now = _clock.nowUtc();
      final existing = await _row(entryId, direction);
      final current = existing == null
          ? ReviewState.initial(now)
          : _stateOf(existing);
      final next = _scheduler.review(current, outcome, now);
      final values = FlashcardsCompanion(
        state: Value(next.state),
        step: Value(next.step),
        stability: Value(next.stability),
        difficulty: Value(next.difficulty),
        due: Value(next.due),
        lastReviewedAt: Value(next.lastReviewedAt),
        reviewCount: Value(next.reviewCount),
        lapseCount: Value(next.lapseCount),
        schedulerVersion: Value(next.schedulerVersion),
        updatedAt: Value(now),
      );
      if (existing == null) {
        await _db
            .into(_db.flashcards)
            .insert(
              values.copyWith(
                id: Value(_ids.newId()),
                entryId: Value(entryId),
                direction: Value(direction),
                createdAt: Value(now),
              ),
            );
      } else {
        await (_db.update(
          _db.flashcards,
        )..where((c) => c.id.equals(existing.id))).write(values);
      }

      final event = ReviewEvent(
        id: _ids.newId(),
        entryId: entryId,
        sessionId: sessionId,
        direction: direction,
        outcome: outcome,
        reviewedAt: now,
        localDay: LocalDay.of(_clock.toLocal(now)),
      );
      await _db
          .into(_db.reviewEvents)
          .insert(
            ReviewEventsCompanion.insert(
              id: event.id,
              entryId: Value(entryId),
              sessionId: sessionId,
              direction: direction,
              outcome: outcome,
              reviewedAt: now,
              localDay: event.localDay.toString(),
            ),
          );
      return (next, event);
    });
  });

  @override
  Future<ReviewState?> cardState(String entryId, CardDirection direction) =>
      _guard('cardState', () async {
        final row = await _row(entryId, direction);
        return row == null ? null : _stateOf(row);
      });

  Future<FlashcardRow?> _row(String entryId, CardDirection direction) =>
      (_db.select(_db.flashcards)..where(
            (c) =>
                c.entryId.equals(entryId) & c.direction.equalsValue(direction),
          ))
          .getSingleOrNull();

  ReviewState _stateOf(FlashcardRow row) => ReviewState(
    state: row.state,
    step: row.step,
    stability: row.stability,
    difficulty: row.difficulty,
    due: row.due,
    lastReviewedAt: row.lastReviewedAt,
    reviewCount: row.reviewCount,
    lapseCount: row.lapseCount,
    schedulerVersion: row.schedulerVersion,
  );

  /// Local midnight of [nowUtc]'s day, as a UTC instant.
  DateTime _startOfLocalDay(DateTime nowUtc) {
    final local = _clock.toLocal(nowUtc);
    return nowUtc.subtract(
      Duration(
        hours: local.hour,
        minutes: local.minute,
        seconds: local.second,
        milliseconds: local.millisecond,
        microseconds: local.microsecond,
      ),
    );
  }

  Future<T> _guard<T>(String operation, Future<T> Function() body) async {
    try {
      return await body();
    } on AppException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw StorageException(operation, error, stackTrace);
    }
  }
}
