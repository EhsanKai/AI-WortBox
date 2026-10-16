import '../../../core/config/app_config.dart';
import 'text_tokenizer.dart';

/// Finds the sentence around a selection, for storing as source context.
abstract final class SentenceContext {
  // Common German abbreviations whose period does not end a sentence.
  static const _abbreviations = {
    'z',
    'b',
    'd',
    'h',
    'u',
    'a',
    'o',
    'ä',
    'usw',
    'bzw',
    'ca',
    'dr',
    'prof',
    'hr',
    'fr',
    'frl',
    'nr',
    's',
    'vgl',
    'etc',
    'evtl',
    'ggf',
    'inkl',
    'jh',
    'mio',
    'mrd',
    'st',
    'str',
    'bspw',
    'sog',
    'geb',
    'gest',
    'abb',
    'kap',
    'bd',
    'hrsg',
    'zit',
    'm',
    'dt',
    'engl',
    'lat',
    'ggü',
    'v',
    'chr',
  };

  static final _paragraphBreak = RegExp(r'\n[ \t]*\n');
  static final _whitespace = RegExp(r'\s+');

  /// The sentence(s) of [text] covering the range [start, end), with line
  /// breaks turned into spaces and hyphenated line breaks joined. Long
  /// sentences are shortened around the selection with "…".
  static String around(String text, int start, int end) {
    var from = _sentenceStart(text, start);
    var to = _sentenceEnd(text, end);
    if (to < from) to = from;
    final sentence = _clean(text.substring(from, to));
    if (sentence.length <= AppConfig.maxContextLength) return sentence;

    // Keep a window around the selection, within the length limit.
    final budget = AppConfig.maxContextLength - (end - start);
    final half = budget > 0 ? budget ~/ 2 : 0;
    final windowFrom = (start - half).clamp(from, to);
    to = (end + half).clamp(from, to);
    from = windowFrom;
    return '…${_clean(text.substring(from, to))}…';
  }

  static int _sentenceStart(String text, int offset) {
    var paragraphStart = 0;
    for (final m in _paragraphBreak.allMatches(text)) {
      if (m.end <= offset) paragraphStart = m.end;
    }
    for (var i = offset - 1; i >= paragraphStart; i--) {
      if (_isBoundary(text, i)) return i + 1;
    }
    return paragraphStart;
  }

  static int _sentenceEnd(String text, int offset) {
    var paragraphEnd = text.length;
    for (final m in _paragraphBreak.allMatches(text)) {
      if (m.start >= offset) {
        paragraphEnd = m.start;
        break;
      }
    }
    for (var i = offset; i < paragraphEnd; i++) {
      if (_isBoundary(text, i)) {
        // Include closing quotes/brackets right after the punctuation.
        var j = i + 1;
        while (j < paragraphEnd && '"“”»«’)'.contains(text[j])) {
          j++;
        }
        return j;
      }
    }
    return paragraphEnd;
  }

  /// Whether the character at [i] ends a sentence.
  static bool _isBoundary(String text, int i) {
    final c = text[i];
    if (c != '.' && c != '!' && c != '?' && c != '…') return false;
    // Must be followed by whitespace (or quotes then whitespace) or the end.
    var j = i + 1;
    while (j < text.length && '"“”»«’)'.contains(text[j])) {
      j++;
    }
    if (j < text.length && !RegExp(r'\s').hasMatch(text[j])) return false;
    if (c != '.') return true;

    // "3. Mai", "z. B.", "Dr. Müller": not a sentence end.
    final before = RegExp(
      r'([\p{L}\d]+)$',
      unicode: true,
    ).firstMatch(text.substring(0, i))?.group(1);
    if (before != null) {
      if (RegExp(r'^\d+$').hasMatch(before)) return false;
      if (_abbreviations.contains(before.toLowerCase())) return false;
    }
    // Followed by a lowercase word: probably not a sentence end.
    final next = RegExp(
      r'^\s*(\p{L})',
      unicode: true,
    ).firstMatch(text.substring(j));
    if (next != null) {
      final letter = next.group(1)!;
      if (letter == letter.toLowerCase() && letter != letter.toUpperCase()) {
        return false;
      }
    }
    return true;
  }

  static String _clean(String text) {
    final joined = TextTokenizer.tokenize(text).map((t) => t.display).join();
    return joined.replaceAll(_whitespace, ' ').trim();
  }
}
