/// Text normalization helpers shared by validation and duplicate detection.
///
/// Normalized forms are used for *comparison only*. The original spelling a
/// user entered is always stored and displayed unchanged.
abstract final class TextNormalizer {
  static final _whitespace = RegExp(r'\s+');

  // Characters trimmed from the edges of vocabulary items (common OCR/CSV
  // noise). Inner punctuation such as hyphens or apostrophes is preserved.
  static final _edgePunctuation = RegExp(
    r'^[\s.,;:!?"«»„“”‚‘’()\[\]{}…]+|[\s.,;:!?"«»„“”‚‘’()\[\]{}…]+$',
  );

  // Dart has no built-in Unicode NFC normalization. Compose the decomposed
  // forms that occur in German text (base letter + U+0308 COMBINING
  // DIAERESIS) so that "ä" typed two different ways compares equal.
  static const _germanComposition = {
    'ä': 'ä',
    'ö': 'ö',
    'ü': 'ü',
    'Ä': 'Ä',
    'Ö': 'Ö',
    'Ü': 'Ü',
  };

  // Persian text often contains Arabic code points that look identical.
  static const _persianUnification = {
    'ي': 'ی', // ARABIC LETTER YEH -> FARSI YEH
    'ى': 'ی', // ALEF MAKSURA -> FARSI YEH
    'ك': 'ک', // ARABIC KAF -> KEHEH
  };

  /// Trims and collapses internal whitespace to single spaces.
  static String collapseWhitespace(String input) =>
      input.trim().replaceAll(_whitespace, ' ');

  /// Composes German umlauts and unifies Arabic/Persian look-alike letters.
  static String composeCharacters(String input) {
    var result = input;
    _germanComposition.forEach(
      (from, to) => result = result.replaceAll(from, to),
    );
    _persianUnification.forEach(
      (from, to) => result = result.replaceAll(from, to),
    );
    return result;
  }

  /// Display-safe cleanup for names: composed characters, collapsed spaces.
  static String cleanName(String input) =>
      collapseWhitespace(composeCharacters(input));

  /// Case-insensitive comparison key for names.
  static String nameKey(String input) => cleanName(input).toLowerCase();

  /// Comparison key for vocabulary items: composed characters, collapsed
  /// whitespace, edge punctuation removed, lower-cased. Does not lemmatize.
  static String vocabularyKey(String input) => collapseWhitespace(
    composeCharacters(input).replaceAll(_edgePunctuation, ''),
  ).toLowerCase();
}
