import 'package:flutter/foundation.dart';

import '../../csv_import/domain/csv_import_analysis.dart' show splitMeanings;
import '../../vocabulary/domain/vocabulary_draft.dart';
import '../../vocabulary/domain/vocabulary_entry.dart';
import 'lemma_hints.dart';

/// One selected item on the review screen, editable before saving.
@immutable
class ScanReviewItem {
  const ScanReviewItem({
    required this.id,
    required this.original,
    required this.context,
    this.lemma = '',
    this.meaning = '',
    this.hint,
    this.stroke,
  });

  /// Stable within the session (used as a widget key).
  final int id;

  /// German word or expression as selected, corrected by the user if needed.
  final String original;

  /// Sentence the item was selected from (editable).
  final String context;

  /// Optional base form entered by the user or taken from [hint].
  final String lemma;

  /// Optional Persian meaning(s), separated by ; ؛ or |.
  final String meaning;

  /// Offline base-form suggestion; never applied automatically.
  final LemmaHint? hint;

  /// Id of the photo highlight this item was read from, if any.
  final int? stroke;

  ScanReviewItem copyWith({
    String? original,
    String? context,
    String? lemma,
    String? meaning,
  }) => ScanReviewItem(
    id: id,
    original: original ?? this.original,
    context: context ?? this.context,
    lemma: lemma ?? this.lemma,
    meaning: meaning ?? this.meaning,
    hint: original == null || original == this.original
        ? hint
        : LemmaHints.suggest(original),
    stroke: stroke,
  );

  /// The vocabulary draft saved for this item.
  VocabularyDraft toDraft(String deckId) => VocabularyDraft(
    deckId: deckId,
    original: original,
    meanings: [for (final m in splitMeanings(meaning)) VocabularyMeaning(m)],
    lemma: lemma,
    sourceContext: context,
    sourceType: VocabularySourceType.image,
  ).cleaned();
}
