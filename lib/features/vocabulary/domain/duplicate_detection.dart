import 'package:flutter/foundation.dart';

import '../../../core/text/text_normalizer.dart';
import 'vocabulary_draft.dart';
import 'vocabulary_entry.dart';

/// Duplicates are detected by the normalized source word within one deck.
///
/// A duplicate is *redundant* when it adds no new meaning (its meanings are a
/// subset of an existing entry's meanings, including "no meanings"). Same word
/// with different meanings is never merged automatically: the word may have
/// several senses, so the user decides.
sealed class DuplicateCheck {
  const DuplicateCheck();
}

final class NoDuplicate extends DuplicateCheck {
  const NoDuplicate();
}

/// The word already exists and the draft adds no new meanings.
final class RedundantDuplicate extends DuplicateCheck {
  const RedundantDuplicate(this.existing);

  final VocabularyEntry existing;
}

/// The word already exists with other meanings.
final class SameWordDifferentMeanings extends DuplicateCheck {
  const SameWordDifferentMeanings(this.existing);

  /// Matching entries, oldest first.
  final List<VocabularyEntry> existing;
}

/// Compares [draft] against [existing] entries of the same deck.
/// [excludeEntryId] skips the entry being edited.
DuplicateCheck checkDuplicate(
  VocabularyDraft draft,
  Iterable<VocabularyEntry> existing, {
  String? excludeEntryId,
}) {
  final key = draft.normalized;
  final matches =
      existing
          .where(
            (e) =>
                e.deckId == draft.deckId &&
                e.normalized == key &&
                e.id != excludeEntryId,
          )
          .toList()
        ..sort(_oldestFirst);
  if (matches.isEmpty) return const NoDuplicate();

  final keys = draft.meaningKeys;
  for (final match in matches) {
    if (match.meaningKeys.containsAll(keys)) return RedundantDuplicate(match);
  }
  return SameWordDifferentMeanings(matches);
}

/// How CSV rows whose word already exists (in the deck or earlier in the
/// file) are handled. Rows that add no new meaning are always skipped.
enum DuplicateStrategy {
  /// Skip every row whose word already exists.
  skip,

  /// Add the row's new meanings to the existing (oldest) entry, and fill its
  /// empty optional fields. Existing content is never overwritten.
  mergeMeanings,

  /// Create a separate entry when the meanings differ.
  keepSeparate,
}

/// A valid, cleaned draft from import row [rowNumber] (1-based data row).
@immutable
class ImportCandidate {
  const ImportCandidate({
    required this.rowNumber,
    required this.draft,
    this.tags = const [],
  });

  final int rowNumber;
  final VocabularyDraft draft;

  /// Tag names to add to the entry the row creates or merges into. Skipped
  /// rows add no tags.
  final List<String> tags;
}

/// What happens to one import candidate.
sealed class ImportDecision {
  const ImportDecision(this.rowNumber);

  final int rowNumber;
}

final class CreateDecision extends ImportDecision {
  const CreateDecision(super.rowNumber);
}

/// Add meanings to an entry that already exists in the deck.
final class MergeIntoEntryDecision extends ImportDecision {
  const MergeIntoEntryDecision(super.rowNumber, this.entryId);

  final String entryId;
}

/// Add meanings to the entry created by an earlier row of the same import.
final class MergeIntoRowDecision extends ImportDecision {
  const MergeIntoRowDecision(super.rowNumber, this.targetRowNumber);

  final int targetRowNumber;
}

enum SkipReason {
  /// The word exists and the row adds no new meaning.
  redundant,

  /// The word exists and [DuplicateStrategy.skip] was chosen.
  wordExists,
}

final class SkipDecision extends ImportDecision {
  const SkipDecision(
    super.rowNumber,
    this.reason, {
    this.entryId,
    this.targetRowNumber,
  });

  final SkipReason reason;

  /// Set when the duplicate is an existing entry.
  final String? entryId;

  /// Set when the duplicate is an earlier row of the same file.
  final int? targetRowNumber;

  bool get isDuplicateInFile => targetRowNumber != null;
}

/// Decides deterministically what to do with each candidate, in row order.
///
/// Earlier rows of the file are treated like existing entries, so the result
/// only depends on the input order, the existing entries and [strategy].
List<ImportDecision> planImport(
  List<ImportCandidate> candidates,
  Iterable<VocabularyEntry> existing,
  DuplicateStrategy strategy,
) {
  final pool = <String, List<_Target>>{};
  final sortedExisting = existing.toList()..sort(_oldestFirst);
  for (final entry in sortedExisting) {
    pool
        .putIfAbsent(entry.normalized, () => [])
        .add(_Target.entry(entry.id, entry.meaningKeys));
  }

  final decisions = <ImportDecision>[];
  for (final candidate in candidates) {
    final key = candidate.draft.normalized;
    final keys = candidate.draft.meaningKeys;
    final targets = pool.putIfAbsent(key, () => []);

    if (targets.isEmpty) {
      decisions.add(CreateDecision(candidate.rowNumber));
      targets.add(_Target.row(candidate.rowNumber, keys));
      continue;
    }

    final redundantTarget = targets
        .where((t) => t.meaningKeys.containsAll(keys))
        .firstOrNull;
    if (redundantTarget != null) {
      decisions.add(
        SkipDecision(
          candidate.rowNumber,
          SkipReason.redundant,
          entryId: redundantTarget.entryId,
          targetRowNumber: redundantTarget.rowNumber,
        ),
      );
      continue;
    }

    final first = targets.first;
    switch (strategy) {
      case DuplicateStrategy.skip:
        decisions.add(
          SkipDecision(
            candidate.rowNumber,
            SkipReason.wordExists,
            entryId: first.entryId,
            targetRowNumber: first.rowNumber,
          ),
        );
      case DuplicateStrategy.mergeMeanings:
        decisions.add(
          first.entryId != null
              ? MergeIntoEntryDecision(candidate.rowNumber, first.entryId!)
              : MergeIntoRowDecision(candidate.rowNumber, first.rowNumber!),
        );
        first.meaningKeys.addAll(keys);
      case DuplicateStrategy.keepSeparate:
        decisions.add(CreateDecision(candidate.rowNumber));
        targets.add(_Target.row(candidate.rowNumber, keys));
    }
  }
  return decisions;
}

/// Returns [base] with [extra]'s new meanings appended and [base]'s empty
/// optional fields filled from [extra]. Nothing in [base] is overwritten.
VocabularyDraft mergeDrafts(VocabularyDraft base, VocabularyDraft extra) {
  final existingKeys = base.meaningKeys;
  final added = extra.meanings.where(
    (m) => existingKeys.add(TextNormalizer.meaningKey(m.text)),
  );
  return VocabularyDraft(
    deckId: base.deckId,
    original: base.original,
    meanings: [...base.meanings, ...added],
    lemma: base.lemma ?? extra.lemma,
    partOfSpeech: base.partOfSpeech ?? extra.partOfSpeech,
    exampleSentence: base.exampleSentence ?? extra.exampleSentence,
    exampleTranslation: base.exampleTranslation ?? extra.exampleTranslation,
    grammarInfo: base.grammarInfo ?? extra.grammarInfo,
    notes: base.notes ?? extra.notes,
    sourceContext: base.sourceContext ?? extra.sourceContext,
    sourceType: base.sourceType,
  );
}

int _oldestFirst(VocabularyEntry a, VocabularyEntry b) {
  final byDate = a.createdAt.compareTo(b.createdAt);
  return byDate != 0 ? byDate : a.id.compareTo(b.id);
}

class _Target {
  _Target.entry(String this.entryId, Set<String> keys)
    : rowNumber = null,
      meaningKeys = {...keys};

  _Target.row(int this.rowNumber, Set<String> keys)
    : entryId = null,
      meaningKeys = {...keys};

  final String? entryId;
  final int? rowNumber;
  final Set<String> meaningKeys;
}
