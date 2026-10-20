import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../vocabulary/domain/vocabulary_entry.dart';
import '../../vocabulary/domain/vocabulary_repository.dart';
import '../domain/memory_coach.dart';
import '../domain/review_event.dart';

/// A word the Memory Coach suggests, with its current content.
@immutable
class CoachSuggestion {
  const CoachSuggestion(this.entry, this.evidence);

  final VocabularyEntry entry;
  final StrugglingWord evidence;
}

/// The rule in use; overridable in tests.
final memoryCoachRuleProvider = Provider<MemoryCoachRule>(
  (ref) => MemoryCoachRule.standard,
);

/// Words that need practice under [memoryCoachRuleProvider], updated when
/// reviews are recorded or words deleted. Reads only: no schedule or
/// history is written by watching or opening it.
final coachSuggestionsProvider =
    StreamProvider.autoDispose<List<CoachSuggestion>>((ref) {
      final rule = ref.watch(memoryCoachRuleProvider);
      final clock = ref.watch(clockProvider);
      final vocabulary = ref.watch(vocabularyRepositoryProvider);
      return ref
          .watch(reviewRepositoryProvider)
          .watchEventsSince(clock.nowUtc().subtract(rule.lookback))
          .asyncMap(
            (events) => resolveSuggestions(
              events,
              now: clock.nowUtc(),
              rule: rule,
              vocabulary: vocabulary,
            ),
          );
    });

/// Applies [rule] to [events] and loads the words that qualify, in the
/// rule's order. Words deleted meanwhile are left out.
Future<List<CoachSuggestion>> resolveSuggestions(
  List<ReviewEvent> events, {
  required DateTime now,
  required MemoryCoachRule rule,
  required VocabularyRepository vocabulary,
}) async => [
  for (final word in findStrugglingWords(events, now: now, rule: rule))
    if (await vocabulary.getEntry(word.entryId) case final entry?)
      CoachSuggestion(entry, word),
];
