import 'package:flutter/foundation.dart';

import '../../../core/text/text_normalizer.dart';

/// Search over the word, its base form and its meanings.
///
/// Matching works on comparison keys derived from the stored text; the
/// stored text itself is never changed:
/// - German: [TextNormalizer.vocabularyKey] (case-insensitive, umlauts
///   composed, edge punctuation and extra spaces ignored);
/// - Persian: [TextNormalizer.meaningKey] (Arabic/Persian letter variants
///   unified, diacritics ignored), and the zero-width non-joiner (U+200C) is
///   ignored, so "می‌روم" and "میروم" match. A space is *not* treated like
///   a ZWNJ.
abstract final class VocabularySearch {
  static const _zwnj = '‌';

  static String _meaningKey(String text) =>
      TextNormalizer.meaningKey(text).replaceAll(_zwnj, '');

  /// The stored search key of an entry: one comparison key per line.
  static String keyFor({
    required String original,
    String? lemma,
    Iterable<String> meanings = const [],
  }) => {
    TextNormalizer.vocabularyKey(original),
    if (lemma != null && lemma.trim().isNotEmpty)
      TextNormalizer.vocabularyKey(lemma),
    for (final m in meanings) _meaningKey(m),
  }.where((k) => k.isNotEmpty).join('\n');

  /// Keys a query is matched with (an entry matches if its search key
  /// contains any of them). Empty for a blank query.
  static Set<String> queryKeys(String query) => {
    TextNormalizer.vocabularyKey(query),
    _meaningKey(query),
  }.where((k) => k.isNotEmpty && !k.contains('\n')).toSet();
}

/// Filters for the vocabulary list. All criteria are combined with AND.
@immutable
class VocabularyQuery {
  const VocabularyQuery({
    this.text = '',
    this.deckId,
    this.tagId,
    this.difficultOnly = false,
    this.missingMeaningOnly = false,
  });

  /// Free text (German or Persian). Blank means no text filter.
  final String text;

  /// Limit to one deck; null searches every deck.
  final String? deckId;

  /// Only entries with this tag.
  final String? tagId;

  /// Only entries marked as difficult.
  final bool difficultOnly;

  /// Only entries without a meaning: no meaning row, or only meanings that
  /// are blank (whitespace). Examples, notes and grammar do not count.
  final bool missingMeaningOnly;

  /// Whether anything besides the deck restricts the list.
  bool get isFiltered =>
      text.trim().isNotEmpty ||
      tagId != null ||
      difficultOnly ||
      missingMeaningOnly;

  VocabularyQuery copyWith({
    String? text,
    String? Function()? tagId,
    bool? difficultOnly,
    bool? missingMeaningOnly,
  }) => VocabularyQuery(
    text: text ?? this.text,
    deckId: deckId,
    tagId: tagId != null ? tagId() : this.tagId,
    difficultOnly: difficultOnly ?? this.difficultOnly,
    missingMeaningOnly: missingMeaningOnly ?? this.missingMeaningOnly,
  );

  @override
  bool operator ==(Object other) =>
      other is VocabularyQuery &&
      other.text == text &&
      other.deckId == deckId &&
      other.tagId == tagId &&
      other.difficultOnly == difficultOnly &&
      other.missingMeaningOnly == missingMeaningOnly;

  @override
  int get hashCode =>
      Object.hash(text, deckId, tagId, difficultOnly, missingMeaningOnly);
}
