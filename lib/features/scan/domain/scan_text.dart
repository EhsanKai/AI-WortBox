import 'dart:ui' show Rect;

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
  }) {
    final buffer = StringBuffer();
    final lines = <RecognizedLine>[];
    for (final block in blocks) {
      final blockLines = [
        for (final (text, box) in block)
          (OcrTextNormalizer.normalizeLine(text), box),
      ].where((l) => l.$1.isNotEmpty).toList();
      if (blockLines.isEmpty) continue;
      if (buffer.isNotEmpty) buffer.write('\n\n');
      for (final (index, (text, box)) in blockLines.indexed) {
        if (index > 0) buffer.write('\n');
        final start = buffer.length;
        buffer.write(text);
        lines.add(RecognizedLine(start: start, end: buffer.length, box: box));
      }
    }
    return ScanText(
      text: buffer.toString(),
      rawText: rawText,
      origin: ScanTextOrigin.ocr,
      lines: List.unmodifiable(lines),
    );
  }

  final String text;
  final String rawText;
  final ScanTextOrigin origin;

  /// Line positions from OCR. Empty for typed or edited text, because
  /// positions are no longer meaningful after the text changed.
  final List<RecognizedLine> lines;

  bool get isBlank => text.trim().isEmpty;

  /// A corrected version of this text. Line positions are dropped.
  ScanText edited(String newText) => ScanText(
    text: OcrTextNormalizer.normalize(newText),
    rawText: rawText,
    origin: ScanTextOrigin.edited,
  );
}
