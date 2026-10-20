import 'dart:ui' show Offset, Rect, Size;

import 'package:ai_wortbox/features/scan/domain/highlight.dart';
import 'package:ai_wortbox/features/scan/domain/image_fit.dart';
import 'package:ai_wortbox/features/scan/domain/scan_text.dart';
import 'package:flutter/widgets.dart'
    show Matrix4, MatrixUtils, TransformationController;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const image = Size(2000, 3000);

  HighlightStroke stroke(List<Offset> points, {double width = 20}) =>
      HighlightStroke(id: 1, points: points, width: width);

  group('OCR region around a highlight', () {
    test('a thin stroke gets padding so whole letters are read', () {
      final s = stroke(const [Offset(500, 1000), Offset(700, 1000)]);
      expect(s.bounds, const Rect.fromLTRB(490, 990, 710, 1010));
      final region = ocrRegionFor(s, image);
      // At least 2 % of the shorter side (40 px) above and below, twice
      // that to the sides.
      expect(region, const Rect.fromLTRB(410, 950, 790, 1050));
      expect(region.contains(s.bounds.topLeft), isTrue);
    });

    test('a wide brush gets padding relative to its width; a second '
        'attempt reads a larger area', () {
      final s = stroke(const [Offset(500, 1000)], width: 100);
      expect(ocrRegionFor(s, image), const Rect.fromLTRB(300, 890, 700, 1110));
      final larger = ocrRegionFor(s, image, margin: 2);
      expect(larger.width, greaterThan(ocrRegionFor(s, image).width));
    });

    test('regions are clipped to the photo', () {
      final s = stroke(const [Offset(5, 3), Offset(1990, 2995)]);
      expect(ocrRegionFor(s, image), Offset.zero & image);
    });
  });

  group('words selected by the finger path', () {
    // A line of words 40 px high at y 1000–1040, next line at 1070–1110.
    const haus = Rect.fromLTWH(400, 1000, 110, 40);
    const und = Rect.fromLTWH(532, 1000, 66, 40);
    const below = Rect.fromLTWH(400, 1070, 110, 40);

    test('a stroke through part of a word selects the whole word', () {
      final s = stroke(const [Offset(420, 1020), Offset(450, 1022)]);
      expect(strokeCovers(s, haus), isTrue);
      expect(strokeCovers(s, und), isFalse, reason: 'not reached');
      expect(strokeCovers(s, below), isFalse, reason: 'other line');
    });

    test('a wide brush on one line does not select the line below', () {
      final s = stroke(const [
        Offset(420, 1015),
        Offset(590, 1018),
      ], width: 120);
      expect(strokeCovers(s, haus), isTrue);
      expect(strokeCovers(s, und), isTrue);
      expect(strokeCovers(s, below), isFalse);
    });

    test('sparse touch points are filled in, so short words between them '
        'are not skipped', () {
      final s = stroke(const [Offset(300, 1020), Offset(700, 1020)]);
      expect(s.samples.length, greaterThan(70));
      expect(strokeCovers(s, und), isTrue);
    });
  });

  group('text read from a highlight', () {
    // OCR of a crop starting at (400, 950), enlarged 2×: crop pixel = 2 ×
    // (photo pixel − crop origin).
    const region = Rect.fromLTWH(400, 950, 400, 300);
    Rect crop(Rect photo) => Rect.fromLTRB(
      (photo.left - 400) * 2,
      (photo.top - 950) * 2,
      (photo.right - 400) * 2,
      (photo.bottom - 950) * 2,
    );
    final recognized = ScanText.fromOcrLayout(
      [
        [
          OcrLine(
            'oben steht',
            elements: [
              OcrElement('oben', crop(const Rect.fromLTWH(400, 950, 90, 40))),
              OcrElement('steht', crop(const Rect.fromLTWH(510, 950, 110, 40))),
            ],
          ),
          OcrLine(
            '„Größe“ und Maß-',
            elements: [
              OcrElement(
                '„Größe“',
                crop(const Rect.fromLTWH(400, 1020, 160, 40)),
              ),
              OcrElement('und', crop(const Rect.fromLTWH(580, 1020, 70, 40))),
              OcrElement('Maß-', crop(const Rect.fromLTWH(670, 1020, 90, 40))),
            ],
          ),
          OcrLine(
            'stab, sagt er.',
            elements: [
              OcrElement(
                'stab,',
                crop(const Rect.fromLTWH(400, 1090, 100, 40)),
              ),
              OcrElement('sagt', crop(const Rect.fromLTWH(520, 1090, 90, 40))),
              OcrElement('er.', crop(const Rect.fromLTWH(630, 1090, 60, 40))),
            ],
          ),
        ],
      ],
      rawText: 'raw',
      imageSize: region.size * 2,
    );

    test('only the covered words, mapped back to photo pixels; German '
        'letters kept, sentence punctuation trimmed', () {
      final s = stroke(const [Offset(430, 1040), Offset(540, 1042)]);
      final text = highlightedText(s, recognized, region: region, scale: 2);
      expect(text.text, 'Größe');
      expect(text.context, '„Größe“ und Maß-');
    });

    test('a word hyphenated at the line end is read without the hyphen '
        '(the user completes it on the review screen)', () {
      final s = stroke(const [Offset(690, 1040), Offset(740, 1041)]);
      final text = highlightedText(s, recognized, region: region, scale: 2);
      expect(text.text, 'Maß');
      expect(text.context, '„Größe“ und Maß-');
    });

    test('words in the padding but off the path are left out', () {
      final s = stroke(const [Offset(590, 1040), Offset(630, 1040)]);
      expect(
        highlightedText(s, recognized, region: region, scale: 2).text,
        'und',
      );
    });

    test('nothing covered: the nearest recognized word is offered', () {
      final s = stroke(const [Offset(570, 1062)]);
      expect(
        highlightedText(s, recognized, region: region, scale: 2).isEmpty,
        isFalse,
      );
    });

    test('without word positions the small region\'s text is used', () {
      final plain = ScanText.fromRecognizedBlocks([
        [('der Bahnhof.', null)],
      ], rawText: 'der Bahnhof.');
      final text = highlightedText(
        stroke(const [Offset(1, 1)]),
        plain,
        region: region,
        scale: 1,
      );
      expect(text.text, 'der Bahnhof');
    });

    test('no text at all → empty', () {
      final empty = ScanText.fromRecognizedBlocks(const [], rawText: '');
      expect(
        highlightedText(
          stroke(const [Offset(1, 1)]),
          empty,
          region: region,
          scale: 1,
        ).isEmpty,
        isTrue,
      );
    });
  });

  group('stroke coordinates', () {
    test('a stroke drawn on the zoomed and panned screen is stored in photo '
        'pixels and drawn back at the same screen position', () {
      // Portrait photo letterboxed in a wide viewport.
      final fit = ImageFit.contain(image, const Size(390, 500));
      expect(fit.offset.dx, greaterThan(0));
      final zoom = TransformationController(
        Matrix4.identity()
          ..translateByDouble(-200, -150, 0, 1)
          ..scaleByDouble(3, 3, 1, 1),
      );
      const screen = [Offset(100, 120), Offset(180, 125)];
      final stored = [for (final p in screen) fit.toImage(zoom.toScene(p))];
      // Drawn by the overlay in viewer coordinates, then zoomed.
      for (final (i, p) in stored.indexed) {
        final back = MatrixUtils.transformPoint(zoom.value, fit.toView(p));
        expect(back.dx, closeTo(screen[i].dx, 1e-6));
        expect(back.dy, closeTo(screen[i].dy, 1e-6));
      }
      // A 20 px brush on screen is 20 / (fit × zoom) photo pixels.
      expect(20 / (fit.scale * 3), closeTo(20 / (500 / 3000 * 3), 1e-9));
      zoom.dispose();
    });
  });

  group('rectangle regions', () {
    test('any drag direction, clipped to the photo; too small is ignored', () {
      expect(
        regionRectFor(const Offset(900, 700), const Offset(100, 300), image),
        const Rect.fromLTRB(100, 300, 900, 700),
      );
      // Dragged past the photo's edges: clipped, not shifted.
      expect(
        regionRectFor(const Offset(-50, -20), const Offset(2100, 400), image),
        const Rect.fromLTRB(0, 0, 2000, 400),
      );
      // Entirely in the letterbox, or thinner than the minimum.
      expect(
        regionRectFor(const Offset(2100, 10), const Offset(2300, 90), image),
        isNull,
      );
      expect(
        regionRectFor(
          const Offset(100, 100),
          const Offset(400, 103),
          image,
          minSide: 5,
        ),
        isNull,
      );
    });

    test('a drag on the zoomed, panned and letterboxed screen maps to the '
        'same photo area', () {
      // Portrait photo letterboxed in a wide viewport, zoomed and panned.
      final fit = ImageFit.contain(image, const Size(390, 500));
      expect(fit.offset.dx, greaterThan(0));
      final transform = Matrix4.identity()
        ..translateByDouble(-200, -150, 0, 1)
        ..scaleByDouble(3, 3, 1, 1);
      const word = Rect.fromLTRB(800, 1200, 1100, 1260);
      Offset screen(Offset p) =>
          MatrixUtils.transformPoint(transform, fit.toView(p));
      final a = fit.toImageThrough(transform, screen(word.topLeft));
      final b = fit.toImageThrough(transform, screen(word.bottomRight));
      final rect = regionRectFor(a, b, image)!;
      expect(rect.left, closeTo(word.left, 1e-6));
      expect(rect.top, closeTo(word.top, 1e-6));
      expect(rect.right, closeTo(word.right, 1e-6));
      expect(rect.bottom, closeTo(word.bottom, 1e-6));
      // A point in the letterbox lies outside the photo.
      expect(
        fit.toImageThrough(Matrix4.identity(), Offset.zero).dx,
        lessThan(0),
      );
    });

    ScanText ocr(String text) => ScanText.fromRecognizedBlocks([
      for (final paragraph in text.split('\n\n'))
        [for (final line in paragraph.split('\n')) (line, null)],
    ], rawText: text);

    test('every readable line becomes one item, in reading order, with its '
        'sentence as context', () {
      final items = regionText(
        ocr('Die Wohnung ist hell.\nDer Balkon ist groß.\n\nAm Abend: Ruhe!'),
      );
      expect(items.map((t) => t.text), [
        'Die Wohnung ist hell',
        'Der Balkon ist groß',
        'Am Abend: Ruhe',
      ]);
      expect(items.first.context, 'Die Wohnung ist hell.');
    });

    test('a word hyphenated across lines is joined and kept with its first '
        'line; lines without words are left out', () {
      final items = regionText(ocr('Die Woh-\nnung ist hell.\n123 / 45'));
      expect(items.map((t) => t.text), ['Die Wohnung', 'ist hell']);
      expect(items.first.context, 'Die Wohnung ist hell.');
    });

    test('nothing readable → no items', () {
      expect(regionText(ocr('')), isEmpty);
      expect(regionText(ocr('12 – 34\n…')), isEmpty);
    });
  });
}
