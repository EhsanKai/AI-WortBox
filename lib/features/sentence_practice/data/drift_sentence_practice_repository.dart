import 'package:drift/drift.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/id/id_generator.dart';
import '../../../core/time/clock.dart';
import '../../../data/database/app_database.dart';
import '../domain/sentence_practice.dart';

/// Sentence-practice history in `sentence_practice_events` (schema v3).
/// Touches no other table.
class DriftSentencePracticeRepository implements SentencePracticeRepository {
  DriftSentencePracticeRepository(
    this._db, {
    required this._clock,
    required this._ids,
  });

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  $SentencePracticeEventsTable get _events => _db.sentencePracticeEvents;

  @override
  Future<SentencePracticeEvent> record({
    required String entryId,
    required SentencePracticeDirection direction,
    required SentenceLevel level,
    required SentencePracticeOutcome outcome,
  }) => _guard('recordSentencePractice', () async {
    final event = SentencePracticeEvent(
      id: _ids.newId(),
      entryId: entryId,
      direction: direction,
      level: level,
      outcome: outcome,
      practicedAt: _clock.nowUtc(),
    );
    await _db
        .into(_events)
        .insert(
          SentencePracticeEventsCompanion.insert(
            id: event.id,
            entryId: entryId,
            direction: direction,
            level: level,
            outcome: outcome,
            practicedAt: event.practicedAt,
          ),
        );
    return event;
  });

  @override
  Future<Map<String, DateTime>> lastPracticedByEntry() =>
      _guard('lastSentencePractice', () async {
        final latest = _events.practicedAt.max();
        final query = _db.selectOnly(_events)
          ..addColumns([_events.entryId, latest])
          ..groupBy([_events.entryId]);
        return {
          for (final row in await query.get())
            if (row.read(latest) case final at?)
              row.read(_events.entryId)!: at.toUtc(),
        };
      });

  @override
  Stream<int> watchCount() {
    final count = _events.id.count();
    final query = _db.selectOnly(_events)..addColumns([count]);
    return query.watchSingle().map((row) => row.read(count) ?? 0);
  }

  @override
  Future<int> clearHistory() =>
      _guard('clearSentencePractice', () => _db.delete(_events).go());

  Future<T> _guard<T>(String operation, Future<T> Function() body) async {
    try {
      return await body();
    } on Object catch (error, stackTrace) {
      throw StorageException(operation, error, stackTrace);
    }
  }
}
