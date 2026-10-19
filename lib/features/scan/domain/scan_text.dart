import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import 'ocr_text_normalizer.dart';

/// Where the text of a scan came from.
enum ScanTextOrigin {
  /// On-device OCR of a page image.
  ocr,

  /// Typed or pasted by the user (fallback when OCR fails or is unavailable).
  typed,

  /// OCR or typed text that the user corrected afterwards.
  edited,
}

/// One recognized line: its character range in [ScanText.text] and its
/// position in the source image (pixel coordinates), when known.
@immutable
class RecognizedLine {
  const RecognizedLine({required this.start, required this.end, this.box});

  final int start;
  final int end;
  final Rect? box;
}

/// One word recognized by OCR: its character range in [ScanText.text] and
/// its bounding box in the source image (pixel coordinates of the upright
/// image).
@immutable
class RecognizedWord {
  const RecognizedWord({
    required this.start,
    required this.end,
    required this.box,
    this.confidence,
  });

  final int start;
  final int end;
  final Rect box;

  /// 0–1 when the recognizer reports it (Android); null otherwise.
  final double? confidence;
}

/// A recognized element (usually a word) as reported by the OCR engine.
@immutable
class OcrElement {
  const OcrElement(this.text, this.box, {this.confidence});

  final String text;
  final Rect box;
  final double? confidence;
}

/// A recognized line with its words, as reported by the OCR engine.
@immutable
class OcrLine {
  const OcrLine(this.text, {this.box, this.elements = const []});

  final String text;
  final Rect? box;
  final List<OcrElement> elements;
}

/// The German text a user selects vocabulary from.
///
/// [text] is the normalized text shown to the user; [rawText] is exactly what
/// the recognizer (or the user) produced, kept for diagnostics and so that no
/// recognized content is lost.
@immutable
class ScanText {
  const ScanText({
    required this.text,
    required this.rawText,
    required this.origin,
    this.lines = const [],
    this.words = const [],
    this.imageSize,
  });

  /// Builds a scan text from typed or pasted input.
  factory ScanText.typed(String input) => ScanText(
    text: OcrTextNormalizer.normalize(input),
    rawText: input,
    origin: ScanTextOrigin.typed,
  );

  /// Builds a scan text from recognized lines grouped into blocks
  /// (paragraphs). Lines are joined with `\n`, blocks with a blank line.
  factory ScanText.fromRecognizedBlocks(
    List<List<(String, Rect?)>> blocks, {
    required String rawText,
  }) => ScanText.fromOcrLayout([
    for (final block in blocks)
      [for (final (text, box) in block) OcrLine(text, box: box)],
  ], rawText: rawText);

  /// Like [ScanText.fromRecognizedBlocks], also keeping each word's box so
  /// words can be selected on the photo. [imageSize] is the size of the
  /// upright image the boxes refer to.
  factory ScanText.fromOcrLayout(
    List<List<OcrLine>> blocks, {
    required String rawText,
    Size? imageSize,
  }) {
    final buffer = StringBuffer();
    final lines = <RecognizedLine>[];
    final words = <RecognizedWord>[];
    for (final block in blocks) {
      final blockLines = [
        for (final line in block)
          (OcrTextNormalizer.normalizeLine(line.text), line),
      ].where((l) => l.$1.isNotEmpty).toList();
      if (blockLines.isEmpty) continue;
      if (buffer.isNotEmpty) buffer.write('\n\n');
      for (final (index, (text, line)) in blockLines.indexed) {
        if (index > 0) buffer.write('\n');
        final start = buffer.length;
        buffer.write(text);
        lines.add(
          RecognizedLine(start: start, end: buffer.length, box: line.box),
        );
        // Elements are located in order in the normalized line; one that
        // cannot be found is left out (it is still selectable as text).
        var cursor = 0;
        for (final element in line.elements) {
          final normalized = OcrTextNormalizer.normalizeLine(element.text);
          if (normalized.isEmpty) continue;
          final at = text.indexOf(normalized, cursor);
          if (at < 0) continue;
          cursor = at + normalized.length;
          words.add(
            RecognizedWord(
              start: start + at,
              end: start + cursor,
              box: element.box,
              confidence: element.confidence,
            ),
          );
        }
      }
    }
    // Boxes outside the photo mean they do not refer to the image as shown
    // (e.g. a rotation mismatch); then only the text view is offered.
    final bounds = imageSize == null
        ? null
        : (Offset.zero & imageSize).inflate(imageSize.shortestSide * 0.02);
    final aligned =
        bounds != null && words.every((w) => bounds.contains(w.box.center));
    return ScanText(
      text: buffer.toString(),
      rawText: rawText,
      origin: ScanTextOrigin.ocr,
      lines: List.unmodifiable(lines),
      words: aligned ? List.unmodifiable(words) : const [],
      imageSize: aligned && words.isNotEmpty ? imageSize : null,
    );
  }

  final String text;
  final String rawText;
  final ScanTextOrigin origin;

  /// Line positions from OCR. Empty for typed or edited text, because
  /// positions are no longer meaningful after the text changed.
  final List<RecognizedLine> lines;

  /// Word positions from OCR, in text order. Empty for typed or edited
  /// text, and when the engine reported no word boxes.
  final List<RecognizedWord> words;

  /// Size of the upright source image [words] refer to, when known.
  final Size? imageSize;

  /// Words can be selected directly on the photo.
  bool get hasLayout => imageSize != null && words.isNotEmpty;

  bool get isBlank => text.trim().isEmpty;

  /// A corrected version of this text. Line and word positions are dropped.
  ScanText edited(String newText) => ScanText(
    text: OcrTextNormalizer.normalize(newText),
    rawText: rawText,
    origin: ScanTextOrigin.edited,
  );
}
