import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import '../../../core/text/text_normalizer.dart';
import 'scan_document.dart';
import 'scan_text.dart';
import 'text_tokenizer.dart';
import 'word_selection.dart';

/// One freehand highlight drawn by the user on the page photo.
///
/// Points and width are in pixels of the upright photo, never screen
/// coordinates, so a stroke stays on the same words at any zoom, pan or
/// screen size.
@immutable
class HighlightStroke {
  const HighlightStroke({
    required this.id,
    required this.points,
    required this.width,
  });

  /// Stable within a scan; numbers the selection for the user.
  final int id;
  final List<Offset> points;

  /// Brush width in image pixels.
  final double width;

  /// Area covered by the brush.
  Rect get bounds {
    var left = double.infinity, top = double.infinity;
    var right = -double.infinity, bottom = -double.infinity;
    for (final p in points) {
      left = math.min(left, p.dx);
      top = math.min(top, p.dy);
      right = math.max(right, p.dx);
      bottom = math.max(bottom, p.dy);
    }
    return Rect.fromLTRB(left, top, right, bottom).inflate(width / 2);
  }

  HighlightStroke extendedTo(Offset point) =>
      HighlightStroke(id: id, points: [...points, point], width: width);

  /// The path sampled at most [width] / 4 apart, so short words between two
  /// recorded touch points are not skipped.
  List<Offset> get samples {
    if (points.length < 2) return points;
    final step = math.max(width / 4, 1.0);
    final result = <Offset>[points.first];
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final n = ((b - a).distance / step).ceil();
      for (var k = 1; k <= n; k++) {
        result.add(Offset.lerp(a, b, k / n)!);
      }
    }
    return result;
  }
}

/// The part of the photo read by OCR for [stroke]: the brushed area plus
/// padding, so that characters only partly covered (a thin stroke, one
/// drawn along the top of the letters, or one ending inside a word) are
/// read whole. Clipped to the photo. [margin] enlarges the padding (used
/// for a second attempt).
///
/// The padding is at least a small share of the photo, because the brush
/// can be much thinner than the print when the user zoomed in. Words of
/// neighbouring lines inside the padding are removed afterwards by
/// [strokeCovers].
Rect ocrRegionFor(HighlightStroke stroke, Size imageSize, {double margin = 1}) {
  final b = stroke.bounds;
  final minimum = imageSize.shortestSide * 0.02;
  final horizontal = math.max(1.5 * stroke.width, 2 * minimum) * margin;
  final vertical = math.max(0.6 * stroke.width, minimum) * margin;
  return Rect.fromLTRB(
    b.left - horizontal,
    b.top - vertical,
    b.right + horizontal,
    b.bottom + vertical,
  ).intersect(Offset.zero & imageSize);
}

/// Whether the finger's path selects the word at [box] (image pixels).
///
/// The path is what counts, not the painted width: the brush has a fixed
/// size on screen and can be taller than a line of print. A word is
/// selected when the path runs through its line (within three quarters of
/// the word's height from its middle) and reaches the word (with a slack
/// of at most half a letter height beyond its ends). So the line the
/// finger followed is read, not the lines the brush merely overlaps, and a
/// stroke ending inside a word still selects the whole word.
bool strokeCovers(HighlightStroke stroke, Rect box) {
  final slack = math.min(stroke.width / 4, box.height / 2);
  final band = box.height * 0.75;
  for (final p in stroke.samples) {
    if (p.dx >= box.left - slack &&
        p.dx <= box.right + slack &&
        (p.dy - box.center.dy).abs() <= band) {
      return true;
    }
  }
  return false;
}

/// What OCR found inside a highlight's region.
@immutable
class HighlightText {
  const HighlightText({required this.text, required this.context});

  /// The highlighted word(s), joined in reading order.
  final String text;

  /// The recognized line(s) the highlight lies on, as sentence context.
  final String context;

  bool get isEmpty => text.isEmpty;
}

/// Extracts the highlighted text from [recognized], the OCR result of the
/// crop [region] (image pixels) taken at [scale] crop pixels per image
/// pixel.
///
/// Only words covered by the stroke are kept, in the recognizer's reading
/// order, so neighbouring text inside the padding is left out. When the
/// recognizer reports no word positions, the whole (small) region is used.
/// When words were found but none is covered, the nearest one is kept.
HighlightText highlightedText(
  HighlightStroke stroke,
  ScanText recognized, {
  required Rect region,
  required double scale,
}) {
  final words = recognized.words;
  if (words.isEmpty) {
    final all = _joined(recognized.text);
    return HighlightText(text: _trimEdges(all), context: all);
  }
  Rect toImage(Rect r) => Rect.fromLTRB(
    region.left + r.left / scale,
    region.top + r.top / scale,
    region.left + r.right / scale,
    region.top + r.bottom / scale,
  );

  var kept = [
    for (final w in words)
      if (strokeCovers(stroke, toImage(w.box))) w,
  ];
  if (kept.isEmpty) {
    final centre = stroke.bounds.center;
    kept = [
      words.reduce(
        (a, b) =>
            (toImage(a.box).center - centre).distance <=
                (toImage(b.box).center - centre).distance
            ? a
            : b,
      ),
    ];
  }

  final text = recognized.text;
  int lineOf(RecognizedWord w) =>
      recognized.lines.indexWhere((l) => w.start >= l.start && w.start < l.end);
  final buffer = StringBuffer();
  for (final (i, w) in kept.indexed) {
    if (i > 0) buffer.write(lineOf(kept[i - 1]) == lineOf(w) ? ' ' : '\n');
    buffer.write(text.substring(w.start, w.end));
  }
  final lines = {for (final w in kept) lineOf(w)}.where((i) => i >= 0);
  final context = [
    for (final i in lines)
      text.substring(recognized.lines[i].start, recognized.lines[i].end),
  ].join('\n');
  return HighlightText(
    text: _trimEdges(_joined(buffer.toString())),
    context: _joined(context),
  );
}

/// A rectangle the user drew around text on the page photo. Unlike a
/// [HighlightStroke], everything readable inside it is used.
///
/// [rect] is in pixels of the upright photo, never screen coordinates, and
/// lies inside the photo (see [regionRectFor]).
@immutable
class RegionSelection {
  const RegionSelection({required this.id, required this.rect});

  /// Shares the numbering of highlights within a scan.
  final int id;
  final Rect rect;
}

/// The rectangle spanned by [a] and [b] (photo pixels, in any order),
/// clipped to the photo of [imageSize], or null when less than [minSide]
/// pixels wide or high after clipping (a tap or a slip of the finger).
Rect? regionRectFor(Offset a, Offset b, Size imageSize, {double minSide = 1}) {
  final rect = Rect.fromPoints(a, b).intersect(Offset.zero & imageSize);
  if (rect.width < minSide || rect.height < minSide) return null;
  return rect;
}

/// The text OCR found in a rectangle crop, one item per recognized line in
/// the recognizer's reading order: [HighlightText.text] is the line's words
/// (a word hyphenated across lines is joined and belongs to the line where
/// it starts), [HighlightText.context] the sentence around it within the
/// rectangle. Lines without words (digits, punctuation) are left out; an
/// empty list means nothing readable was found.
List<HighlightText> regionText(ScanText recognized) {
  final document = ScanDocument(recognized);
  if (!document.hasWords) return const [];
  final text = recognized.text;
  // Line ranges from OCR, or from the line breaks when none were reported.
  final lines = recognized.lines.isNotEmpty
      ? [for (final l in recognized.lines) (l.start, l.end)]
      : [for (final m in RegExp(r'[^\n]+').allMatches(text)) (m.start, m.end)];
  int lineOf(int offset) {
    for (final (i, (start, end)) in lines.indexed) {
      if (offset >= start && offset < end) return i;
    }
    return -1;
  }

  final groups = <int, List<TextToken>>{};
  for (final word in document.words) {
    (groups[lineOf(word.start)] ??= []).add(word);
  }
  final result = <HighlightText>[];
  for (final key in groups.keys.toList()..sort()) {
    final words = groups[key]!;
    final range = SelectedRange(words.first.start, words.last.end);
    final selected = _trimEdges(document.selectedText(range));
    if (selected.isEmpty) continue;
    result.add(
      HighlightText(text: selected, context: document.contextOf(range)),
    );
  }
  return result;
}

/// Joins words hyphenated across lines and collapses whitespace.
String _joined(String text) => TextNormalizer.collapseWhitespace(
  ScanDocument(ScanText.typed(text)).tokens.map((t) => t.display).join(),
).trim();

/// Sentence punctuation around a vocabulary item is dropped; inner hyphens,
/// apostrophes and all letters (umlauts, ß) are kept.
String _trimEdges(String text) => text
    .replaceAll(RegExp(r'^[\s.,;:!?"„“”‚‘’»«()\[\]…–—-]+'), '')
    .replaceAll(RegExp(r'[\s.,;:!?"„“”‚‘»«()\[\]…–—-]+$'), '');
