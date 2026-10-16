import 'package:ai_wortbox/features/scan/domain/lemma_hints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('suggests infinitives for listed irregular forms, any case', () {
    expect(LemmaHints.suggest('ging')?.baseForm, 'gehen');
    expect(LemmaHints.suggest('War')?.baseForm, 'sein');
    expect(LemmaHints.suggest('weiß')?.baseForm, 'wissen');
    expect(LemmaHints.suggest('läuft')?.baseForm, 'laufen');
  });

  test('gives no hint when it cannot be derived reliably', () {
    // Ambiguous forms are deliberately excluded.
    expect(LemmaHints.suggest('gestanden'), isNull);
    expect(LemmaHints.suggest('gefallen'), isNull);
    // Unknown words, regular inflection and base forms.
    expect(LemmaHints.suggest('spielte'), isNull);
    expect(LemmaHints.suggest('Häuser'), isNull);
    expect(LemmaHints.suggest('gehen'), isNull);
    // Expressions.
    expect(LemmaHints.suggest('ging nach'), isNull);
    expect(LemmaHints.suggest(''), isNull);
  });
}
