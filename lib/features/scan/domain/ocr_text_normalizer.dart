/// Encoding-level cleanup of recognized or typed German text.
///
/// Only changes that do not alter the wording are applied: line endings,
/// decomposed umlauts, typographic ligatures, soft hyphens, invisible
/// characters and trailing spaces. Words, spelling, punctuation and line
/// breaks are kept. Joining words hyphenated across lines is *not* done here;
/// it happens visibly at selection time (see `TextTokenizer`).
abstract final class OcrTextNormalizer {
  static const _replacements = {
    // Decomposed umlauts (base letter + COMBINING DIAERESIS).
    'a\u0308': 'ä',
    'o\u0308': 'ö',
    'u\u0308': 'ü',
    'A\u0308': 'Ä',
    'O\u0308': 'Ö',
    'U\u0308': 'Ü',
    // Typographic ligatures some fonts and recognizers produce.
    '\uFB00': 'ff',
    '\uFB01': 'fi',
    '\uFB02': 'fl',
    '\uFB03': 'ffi',
    '\uFB04': 'ffl',
    // Soft hyphen and zero-width characters are invisible in print.
    '\u00AD': '',
    '\u200B': '',
    '\uFEFF': '',
    // Non-breaking space.
    '\u00A0': ' ',
  };

  static final _horizontalSpace = RegExp(r'[ \t]+');
  static final _manyBlankLines = RegExp(r'\n{3,}');

  /// Normalizes a single line (no line breaks expected).
  static String normalizeLine(String line) {
    var result = line;
    _replacements.forEach((from, to) => result = result.replaceAll(from, to));
    return result.replaceAll(_horizontalSpace, ' ').trim();
  }

  /// Normalizes multi-line text: unifies line endings, normalizes each line
  /// and limits runs of blank lines to one (a paragraph break).
  static String normalize(String text) {
    final unified = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = unified.split('\n').map(normalizeLine).join('\n');
    return lines.replaceAll(_manyBlankLines, '\n\n').trim();
  }
}
