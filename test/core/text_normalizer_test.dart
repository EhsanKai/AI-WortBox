import 'package:ai_wortbox/core/text/text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextNormalizer.cleanName', () {
    test('trims and collapses whitespace', () {
      expect(TextNormalizer.cleanName('  Der   Vorleser \n'), 'Der Vorleser');
    });

    test('composes decomposed German umlauts', () {
      expect(TextNormalizer.cleanName('Mädchen'), 'Mädchen');
    });

    test('unifies Arabic yeh and kaf with Persian letters', () {
      expect(TextNormalizer.cleanName('كتاب يك'), 'کتاب یک');
    });
  });

  group('TextNormalizer.nameKey', () {
    test('is case-insensitive including umlauts', () {
      expect(TextNormalizer.nameKey('ÜBUNG'), TextNormalizer.nameKey('übung'));
    });
  });

  group('TextNormalizer.vocabularyKey', () {
    test('strips edge punctuation and German quotes', () {
      expect(TextNormalizer.vocabularyKey('„Haus“,'), 'haus');
      expect(TextNormalizer.vocabularyKey('(Fenster).'), 'fenster');
    });

    test('keeps inner punctuation and multi-word expressions', () {
      expect(
        TextNormalizer.vocabularyKey('  sich  Mühe   geben! '),
        'sich mühe geben',
      );
      expect(TextNormalizer.vocabularyKey('E-Mail'), 'e-mail');
    });

    test('keeps ß', () {
      expect(TextNormalizer.vocabularyKey('Straße'), 'straße');
    });
  });
}
