import 'dart:math';

import '../../../core/config/app_config.dart';
import '../../vocabulary/domain/vocabulary_entry.dart';

/// Chooses the target words of a sentence-practice session from saved
/// [entries]. Pure and deterministic for a given [random].
///
/// - Only words with at least one saved meaning are used (the meaning
///   grounds the exercise).
/// - Words practised in sentences within [AppConfig.sentencePracticeRecent]
///   come last, so they repeat only when nothing else is left.
/// - Before that, words that need practice come first: marked difficult,
///   or in [struggling] (the Memory Coach rule over recorded reviews).
/// - Then words never practised in sentences, then the longest ago.
/// - Ties are shuffled.
List<VocabularyEntry> selectPracticeWords(
  List<VocabularyEntry> entries, {
  required Map<String, DateTime> lastPracticed,
  required Set<String> struggling,
  required DateTime nowUtc,
  required int count,
  required Random random,
}) {
  final recentSince = nowUtc.subtract(AppConfig.sentencePracticeRecent);
  final candidates = [
    for (final e in entries)
      if (!e.lacksMeaning)
        (entry: e, last: lastPracticed[e.id], tie: random.nextDouble()),
  ];
  int rank(({VocabularyEntry entry, DateTime? last, double tie}) c) {
    final recent = c.last != null && c.last!.isAfter(recentSince);
    final needsPractice =
        c.entry.isDifficult || struggling.contains(c.entry.id);
    return (recent ? 2 : 0) + (needsPractice ? 0 : 1);
  }

  candidates.sort((a, b) {
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    // Never practised first, then the longest ago.
    final byLast = switch ((a.last, b.last)) {
      (null, null) => 0,
      (null, _) => -1,
      (_, null) => 1,
      (final x?, final y?) => x.compareTo(y),
    };
    if (byLast != 0) return byLast;
    return a.tie.compareTo(b.tie);
  });
  return [for (final c in candidates.take(count)) c.entry];
}
