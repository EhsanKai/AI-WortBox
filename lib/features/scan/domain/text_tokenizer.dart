import 'package:flutter/foundation.dart';

enum TokenKind { word, other }

/// A run of text in [ScanText.text], addressed by character offsets.
@immutable
class TextToken {
  const TextToken({
    required this.kind,
    required this.start,
    required this.end,
    required this.source,
    required this.display,
  });

  final TokenKind kind;
  final int start;
  final int end;

  /// Exact characters of the text between [start] and [end].
  final String source;

  /// How the token is shown and saved. Equals [source] except for words
  /// hyphenated across a line break, which are joined ("Ver-\nständnis" →
  /// "Verständnis"; "Nord-\nSüd" → "Nord-Süd").
  final String display;

  bool get isWord => kind == TokenKind.word;

  bool get isJoinedAcrossLines => source != display;

  @override
  String toString() => 'TextToken($kind, $start-$end, "$display")';
}

/// Splits German text into word tokens and everything else.
///
/// Words are runs of letters (including umlauts and ß) and combining marks,
/// optionally joined by an inner hyphen or apostrophe ("E-Mail", "geht's").
/// Digits are not words.
abstract final class TextTokenizer {
  static final _word = RegExp(
    r"[\p{L}\p{M}]+(?:[-'’][\p{L}\p{M}]+)*",
    unicode: true,
  );

  // A word ending in a hyphen at the end of a line, continued on the next
  // line by a word.
  static final _hyphenBreak = RegExp(
    r"[\p{L}\p{M}]+(?:[-'’][\p{L}\p{M}]+)*-[ \t]*\n[ \t]*[\p{L}\p{M}]+(?:[-'’][\p{L}\p{M}]+)*",
    unicode: true,
  );

  // "Ein-\nund Ausgang": a suspended hyphen before a conjunction is not a
  // hyphenated word.
  static const _conjunctions = {'und', 'oder', 'bis', 'sowie', 'bzw'};

  static List<TextToken> tokenize(String text) {
    final tokens = <TextToken>[];
    var position = 0;

    void addOther(int end) {
      if (end > position) {
        final source = text.substring(position, end);
        tokens.add(
          TextToken(
            kind: TokenKind.other,
            start: position,
            end: end,
            source: source,
            display: source,
          ),
        );
      }
    }

    while (position < text.length) {
      final hyphenated = _hyphenBreak.matchAsPrefix(text, position);
      final joined = hyphenated == null ? null : _join(hyphenated.group(0)!);
      if (hyphenated != null && joined != null) {
        tokens.add(
          TextToken(
            kind: TokenKind.word,
            start: hyphenated.start,
            end: hyphenated.end,
            source: hyphenated.group(0)!,
            display: joined,
          ),
        );
        position = hyphenated.end;
        continue;
      }
      final word = _word.matchAsPrefix(text, position);
      if (word != null) {
        tokens.add(
          TextToken(
            kind: TokenKind.word,
            start: word.start,
            end: word.end,
            source: word.group(0)!,
            display: word.group(0)!,
          ),
        );
        position = word.end;
        continue;
      }
      // Advance to the next possible word start.
      final next = _nextWordStart(text, position + 1);
      addOther(next);
      position = next;
    }
    return tokens;
  }

  static int _nextWordStart(String text, int from) {
    final match = RegExp(
      r'[\p{L}\p{M}]',
      unicode: true,
    ).firstMatch(text.substring(from));
    return match == null ? text.length : from + match.start;
  }

  /// Joins a hyphenated line break, or returns null if it should stay split.
  static String? _join(String source) {
    final parts = source.split(RegExp(r'-[ \t]*\n[ \t]*'));
    if (parts.length != 2) return null;
    final (first, second) = (parts[0], parts[1]);
    if (_conjunctions.contains(second.toLowerCase())) return null;
    final startsLower =
        second[0] == second[0].toLowerCase() &&
        second[0] != second[0].toUpperCase();
    return startsLower ? '$first$second' : '$first-$second';
  }
}
