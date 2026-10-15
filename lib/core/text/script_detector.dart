/// Lightweight script detection for mixed German/Persian content.
abstract final class ScriptDetector {
  // Arabic, Arabic Supplement, Arabic Extended-A, presentation forms, Hebrew.
  static final _rtlLetter = RegExp(
    '[\u0590-\u05FF\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF'
    '\uFB50-\uFDFF\uFE70-\uFEFF]',
  );
  static final _latinLetter = RegExp('[A-Za-z\u00C0-\u024F\u1E9E]');

  /// Whether [text] contains more right-to-left letters than Latin letters.
  static bool isMostlyRtl(String text) {
    final rtl = _rtlLetter.allMatches(text).length;
    final latin = _latinLetter.allMatches(text).length;
    return rtl > latin;
  }

  /// Whether [text] contains more Latin letters than right-to-left letters.
  static bool isMostlyLatin(String text) {
    final rtl = _rtlLetter.allMatches(text).length;
    final latin = _latinLetter.allMatches(text).length;
    return latin > rtl;
  }
}
