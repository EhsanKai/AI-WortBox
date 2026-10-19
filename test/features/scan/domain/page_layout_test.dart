import 'dart:ui' show Offset, Rect, Size;

import 'package:ai_wortbox/features/scan/domain/image_fit.dart';
import 'package:ai_wortbox/features/scan/domain/scan_document.dart';
import 'package:ai_wortbox/features/scan/domain/scan_text.dart';
import 'package:flutter/widgets.dart'
    show Matrix4, MatrixUtils, TransformationController;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const size = Size(1000, 800);
  Rect box(double x, double y, [double w = 100]) => Rect.fromLTWH(x, y, w, 40);

  group('word boxes from OCR', () {
    final text = ScanText.fromOcrLayout(
      [
        [
          OcrLine(
            '„Größe“ und Maß, bitte!',
            elements: [
              OcrElement('„Größe“', box(10, 10), confidence: 0.8),
              OcrElement('und', box(120, 10)),
              OcrElement('Maß,', box(230, 10)),
              OcrElement('bitte!', box(340, 10)),
            ],
          ),
          // Decomposed umlaut (u + combining diaeresis) as some engines
          // report it, and a word hyphenated across lines.
          OcrLine(
            'Mühe mit Verständ-',
            elements: [
              OcrElement('Mühe', box(10, 60)),
              OcrElement('mit', box(120, 60)),
              OcrElement('Verständ-', box(230, 60)),
            ],
          ),
          OcrLine('nis.', elements: [OcrElement('nis.', box(10, 110))]),
        ],
        [
          OcrLine('Zweiter Absatz', elements: [OcrElement('???', box(0, 0))]),
        ],
      ],
      rawText: 'raw',
      imageSize: size,
    );
    final document = ScanDocument(text);

    String wordAt(Offset p) => document.tokenAt(p)!.display;

    test('each element is mapped to its characters in the normalized text', () {
      expect(text.hasLayout, isTrue);
      expect(text.imageSize, size);
      expect(
        [for (final w in text.words) text.text.substring(w.start, w.end)],
        [
          '„Größe“',
          'und',
          'Maß,',
          'bitte!',
          'Mühe',
          'mit',
          'Verständ-',
          'nis.',
        ],
      );
      expect(text.words.first.confidence, 0.8);
    });

    test('a box selects its word: umlauts, ß, punctuation and leading '
        'quotes are handled', () {
      expect(wordAt(const Offset(50, 30)), 'Größe');
      expect(wordAt(const Offset(250, 30)), 'Maß');
      expect(wordAt(const Offset(350, 30)), 'bitte');
      expect(wordAt(const Offset(20, 70)), 'Mühe');
    });

    test('both halves of a hyphenated word select the joined word, and its '
        'selection covers both boxes', () {
      final first = document.tokenAt(const Offset(240, 70))!;
      final second = document.tokenAt(const Offset(20, 120))!;
      expect(first.start, second.start);
      expect(first.display, 'Verständnis');
      expect(document.boxesOf(document.rangeOfWord(first)), [
        box(230, 60),
        box(10, 110),
      ]);
    });

    test('a touch near a box (within the slop) still hits it; far away '
        'hits nothing', () {
      expect(document.tokenAt(const Offset(117, 30)), isNull);
      expect(document.tokenAt(const Offset(117, 30), slop: 6)!.display, 'und');
      expect(document.tokenAt(const Offset(900, 700), slop: 6), isNull);
    });

    test('boxes outside the photo (e.g. rotated) disable the photo view', () {
      final rotated = ScanText.fromOcrLayout(
        [
          [
            OcrLine('Haus', elements: [OcrElement('Haus', box(10, 900))]),
          ],
        ],
        rawText: 'Haus',
        imageSize: size,
      );
      expect(rotated.hasLayout, isFalse);
      expect(rotated.text, 'Haus');
    });

    test('corrected text has no layout', () {
      final edited = text.edited('Größe');
      expect(edited.hasLayout, isFalse);
      expect(edited.words, isEmpty);
    });

    test('no word boxes → no layout, text selection still works', () {
      final plain = ScanText.fromRecognizedBlocks([
        [('Haus', null)],
      ], rawText: 'Haus');
      expect(plain.hasLayout, isFalse);
      expect(ScanDocument(plain).words.single.display, 'Haus');
    });
  });

  group('image ↔ screen mapping', () {
    test('portrait photo in a wide viewport is centred horizontally', () {
      final fit = ImageFit.contain(
        const Size(1000, 2000),
        const Size(400, 600),
      );
      expect(fit.scale, 0.3);
      expect(fit.offset, const Offset(50, 0));
      expect(fit.imageRect, const Rect.fromLTWH(50, 0, 300, 600));
      expect(fit.toView(const Offset(500, 1000)), const Offset(200, 300));
    });

    test('landscape photo in a tall viewport is centred vertically', () {
      final fit = ImageFit.contain(
        const Size(2000, 1000),
        const Size(400, 600),
      );
      expect(fit.scale, 0.2);
      expect(fit.offset, const Offset(0, 200));
      expect(fit.toImage(const Offset(0, 200)), Offset.zero);
    });

    test('round trip and drawn rectangles: any drag direction, clipped to '
        'the photo', () {
      final fit = ImageFit.contain(
        const Size(1000, 2000),
        const Size(400, 600),
      );
      const p = Offset(123, 456);
      final back = fit.toImage(fit.toView(p));
      expect(back.dx, closeTo(p.dx, 1e-9));
      expect(back.dy, closeTo(p.dy, 1e-9));
      // Dragged from bottom-right to top-left, partly outside the photo.
      final rect = fit.toImageRect(
        Rect.fromPoints(const Offset(380, 90), const Offset(20, 30)),
      );
      expect(rect.left, 0);
      expect(rect.right, 1000);
      expect(rect.top, closeTo(100, 1e-9));
      expect(rect.bottom, closeTo(300, 1e-9));
    });

    test('zoom and pan: a screen point maps back to the same image point '
        'through the viewer transform', () {
      final fit = ImageFit.contain(size, const Size(390, 500));
      final controller = TransformationController(
        Matrix4.identity()
          ..translateByDouble(-150, -80, 0, 1)
          ..scaleByDouble(2.5, 2.5, 1, 1),
      );
      const wordCenter = Offset(640, 210);
      final onScreen = MatrixUtils.transformPoint(
        controller.value,
        fit.toView(wordCenter),
      );
      final back = fit.toImage(controller.toScene(onScreen));
      expect(back.dx, closeTo(wordCenter.dx, 1e-6));
      expect(back.dy, closeTo(wordCenter.dy, 1e-6));
      controller.dispose();
    });
  });
}
