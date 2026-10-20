import 'package:drift/drift.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/id/id_generator.dart';
import '../../../core/time/clock.dart';
import '../../../data/database/app_database.dart';
import '../../statistics/domain/study_statistics.dart';
import '../domain/flashcard.dart';
import '../domain/review_event.dart';
import '../domain/review_repository.dart';

class DriftReviewRepository implements ReviewRepository {
  DriftReviewRepository(this._db, {required this._clock, required this._ids});

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  $ReviewEventsTable get _events => _db.reviewEvents;

  @override
  Future<ReviewEvent> record({
    required String entryId,
    required String sessionId,
    required CardDirection direction,
    required ReviewOutcome outcome,
  }) => _guard('recordReview', () async {
    final now = _clock.nowUtc();
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
        .into(_events)
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
    return event;
  });

  @override
  Stream<List<DayActivity>> watchDailyActivity() {
    final count = _events.id.count();
    final remembered = _events.id.count(
      filter: _events.outcome.equalsValue(ReviewOutcome.remembered),
    );
    final query = _db.selectOnly(_events)
      ..addColumns([_events.localDay, count, remembered])
      ..groupBy([_events.localDay]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          DayActivity(
            day: LocalDay.parse(row.read(_events.localDay)!),
            reviews: row.read(count) ?? 0,
            remembered: row.read(remembered) ?? 0,
          ),
      ],
    );
  }

  @override
  Stream<int> watchSessionCount() {
    final sessions = _events.sessionId.count(distinct: true);
    final query = _db.selectOnly(_events)..addColumns([sessions]);
    return query.watchSingle().map((row) => row.read(sessions) ?? 0);
  }

  @override
  Stream<List<ReviewEvent>> watchEventsSince(DateTime since) =>
      _eventsSince(since).watch().map((rows) => rows.map(_toDomain).toList());

  @override
  Future<List<ReviewEvent>> eventsSince(DateTime since) => _guard(
    'eventsSince',
    () async => (await _eventsSince(since).get()).map(_toDomain).toList(),
  );

  SimpleSelectStatement<$ReviewEventsTable, ReviewEventRow> _eventsSince(
    DateTime since,
  ) => _db.select(_events)
    ..where(
      (e) => e.entryId.isNotNull() & e.reviewedAt.isBiggerOrEqualValue(since),
    );

  static ReviewEvent _toDomain(ReviewEventRow row) => ReviewEvent(
    id: row.id,
    entryId: row.entryId,
    sessionId: row.sessionId,
    direction: row.direction,
    outcome: row.outcome,
    reviewedAt: row.reviewedAt.toUtc(),
    localDay: LocalDay.parse(row.localDay),
  );

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
