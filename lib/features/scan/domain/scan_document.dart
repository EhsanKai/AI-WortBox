import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart';

import '../../../core/text/text_normalizer.dart';
import 'scan_text.dart';
import 'sentence_context.dart';
import 'text_tokenizer.dart';
import 'word_selection.dart';

/// A [ScanText] split into tokens, with helpers to turn selections into
/// vocabulary text and sentence context.
@immutable
class ScanDocument {
  ScanDocument(this.scanText)
    : tokens = List.unmodifiable(TextTokenizer.tokenize(scanText.text));

  final ScanText scanText;
  final List<TextToken> tokens;

  String get text => scanText.text;

  late final List<TextToken> words = List.unmodifiable(
    tokens.where((t) => t.isWord),
  );

  bool get hasWords => words.isNotEmpty;

  /// Paragraphs as lists of token indices (split at blank lines).
  late final List<List<int>> paragraphs = _paragraphs();

  List<List<int>> _paragraphs() {
    final result = <List<int>>[[]];
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (!token.isWord && token.source.contains(RegExp(r'\n[ \t]*\n'))) {
        // Keep the separator (it may carry punctuation such as "." before
        // the break) and start a new paragraph after it.
        result.last.add(i);
        result.add([]);
        continue;
      }
      result.last.add(i);
    }
    return [
      for (final p in result)
        if (p.any((i) => tokens[i].isWord)) p,
    ];
  }

  /// The range covering a single word token.
  SelectedRange rangeOfWord(TextToken word) =>
      SelectedRange(word.start, word.end);

  /// The range from word [a] to word [b] (in either order), or null if they
  /// are in different paragraphs or span more than [maxWords] words.
  SelectedRange? rangeBetween(
    TextToken a,
    TextToken b, {
    required int maxWords,
  }) {
    final (first, last) = a.start <= b.start ? (a, b) : (b, a);
    final between = words.where(
      (w) => w.start >= first.start && w.end <= last.end,
    );
    if (between.length > maxWords) return null;
    final gap = text.substring(first.end, last.start);
    if (RegExp(r'\n[ \t]*\n').hasMatch(gap)) return null;
    return SelectedRange(first.start, last.end);
  }

  /// The vocabulary text of [range]: joined hyphenation, single spaces,
  /// original spelling and capitalization.
  String selectedText(SelectedRange range) {
    final joined = tokens
        .where((t) => t.start >= range.start && t.end <= range.end)
        .map((t) => t.display)
        .join();
    return TextNormalizer.collapseWhitespace(joined);
  }

  /// The sentence around [range].
  String contextOf(SelectedRange range) =>
      SentenceContext.around(text, range.start, range.end);

  // ---------------------------------------------------------------------------
  // Page layout (OCR word boxes in image pixels)

  List<RecognizedWord> get recognizedWords => scanText.words;

  /// The word token a recognized word belongs to (the first one it
  /// overlaps; leading punctuation such as „ is skipped), or null when it
  /// contains no letters.
  TextToken? tokenFor(RecognizedWord word) =>
      words.where((t) => t.start < word.end && word.start < t.end).firstOrNull;

  /// The recognized word at [imagePoint]: the box containing it, or else the
  /// nearest box within [slop] pixels (fingers are wider than small print).
  RecognizedWord? recognizedWordAt(Offset imagePoint, {double slop = 0}) {
    RecognizedWord? nearest;
    var best = double.infinity;
    for (final word in recognizedWords) {
      if (word.box.contains(imagePoint)) return word;
      final distance = _distance(word.box, imagePoint);
      if (distance <= slop && distance < best) {
        best = distance;
        nearest = word;
      }
    }
    return nearest;
  }

  /// The word token at [imagePoint] (see [recognizedWordAt]).
  TextToken? tokenAt(Offset imagePoint, {double slop = 0}) {
    final word = recognizedWordAt(imagePoint, slop: slop);
    return word == null ? null : tokenFor(word);
  }

  /// Boxes of the recognized words inside [range], e.g. both halves of a
  /// word hyphenated across lines.
  List<Rect> boxesOf(SelectedRange range) => [
    for (final w in recognizedWords)
      if (w.start < range.end && range.start < w.end) w.box,
  ];

  static double _distance(Rect box, Offset p) {
    final dx = p.dx < box.left
        ? box.left - p.dx
        : (p.dx > box.right ? p.dx - box.right : 0.0);
    final dy = p.dy < box.top
        ? box.top - p.dy
        : (p.dy > box.bottom ? p.dy - box.bottom : 0.0);
    return dx > dy ? dx : dy;
  }
}
