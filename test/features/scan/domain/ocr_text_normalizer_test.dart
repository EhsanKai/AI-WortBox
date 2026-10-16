import 'dart:ui' show Rect;

import 'package:ai_wortbox/features/scan/domain/ocr_text_normalizer.dart';
import 'package:ai_wortbox/features/scan/domain/scan_text.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OcrTextNormalizer', () {
    test('keeps umlauts, ß, punctuation and German quotes unchanged', () {
      const text =
          '„Größere Straßen?“ – fragte er; (ja!) Übermäßig: äöü ÄÖÜ ß ẞ…';
      expect(OcrTextNormalizer.normalize(text), text);
    });

    test('composes decomposed umlauts', () {
      expect(
        OcrTextNormalizer.normalize('Ma\u0308dchen U\u0308bung o\u0308ffnen'),
        'Mädchen Übung öffnen',
      );
    });

    test('expands ligatures and removes soft hyphens and zero-width chars', () {
      expect(
        OcrTextNormalizer.normalizeLine('\uFB01nden \uFB02ach'),
        'finden flach',
      );
      expect(
        OcrTextNormalizer.normalizeLine('Ver\u00ADständ\u200Bnis\uFEFF'),
        'Verständnis',
      );
    });

    test(
      'unifies line endings, trims lines, keeps line and paragraph breaks',
      () {
        expect(
          OcrTextNormalizer.normalize(
            '  Erste  Zeile \r\nzweite\tZeile\r\r\n\n\nNeu\u00A0Absatz ',
          ),
          'Erste Zeile\nzweite Zeile\n\nNeu Absatz',
        );
      },
    );

    test('does not join hyphenated line breaks (done visibly later)', () {
      expect(OcrTextNormalizer.normalize('Ver-\nständnis'), 'Ver-\nständnis');
    });
  });

  group('ScanText', () {
    test('builds text and line positions from recognized blocks', () {
      const box = Rect.fromLTWH(1, 2, 3, 4);
      final text = ScanText.fromRecognizedBlocks([
        [('Das  Haus', box), ('ist groß.', null)],
        [('', null)],
        [('Neuer Absatz', null)],
      ], rawText: 'raw');
      expect(text.text, 'Das Haus\nist groß.\n\nNeuer Absatz');
      expect(text.origin, ScanTextOrigin.ocr);
      expect(text.rawText, 'raw');
      expect(text.lines.map((l) => text.text.substring(l.start, l.end)), [
        'Das Haus',
        'ist groß.',
        'Neuer Absatz',
      ]);
      expect(text.lines.first.box, box);
    });

    test('typed and edited text have no line positions', () {
      final typed = ScanText.typed(' Ich lese.\r\n');
      expect(typed.text, 'Ich lese.');
      expect(typed.origin, ScanTextOrigin.typed);
      final edited = typed.edited('Ich lese gern.');
      expect(edited.origin, ScanTextOrigin.edited);
      expect(edited.text, 'Ich lese gern.');
      expect(edited.rawText, ' Ich lese.\r\n');
      expect(ScanText.typed(' \n ').isBlank, isTrue);
    });
  });
}
