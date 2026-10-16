import 'package:ai_wortbox/features/scan/domain/text_tokenizer.dart';
import 'package:flutter_test/flutter_test.dart';

List<String> words(String text) => [
  for (final t in TextTokenizer.tokenize(text))
    if (t.isWord) t.display,
];

void main() {
  test('words include umlauts, ß, inner hyphens and apostrophes', () {
    expect(words('Die Straße, „Übermäßig“ – E-Mail geht’s gut! 42 Mal.'), [
      'Die',
      'Straße',
      'Übermäßig',
      'E-Mail',
      'geht’s',
      'gut',
      'Mal',
    ]);
  });

  test('tokens cover the whole text with exact offsets', () {
    const text = 'Er sagte: „Nein.“\nGut';
    final tokens = TextTokenizer.tokenize(text);
    expect(tokens.map((t) => t.source).join(), text);
    for (final t in tokens) {
      expect(text.substring(t.start, t.end), t.source);
    }
  });

  test('joins words hyphenated across a line break', () {
    final tokens = TextTokenizer.tokenize('das Ver-\nständnis und Nord-\nSüd');
    final joined = tokens.where((t) => t.isJoinedAcrossLines).toList();
    expect(joined.map((t) => t.display), ['Verständnis', 'Nord-Süd']);
    expect(joined.first.source, 'Ver-\nständnis');
  });

  test('keeps suspended hyphens before conjunctions', () {
    expect(words('Ein-\nund Ausgang'), ['Ein', 'und', 'Ausgang']);
  });

  test('a hyphen at a line end followed by a new sentence is not joined', () {
    expect(words('Ende -\nAnfang'), ['Ende', 'Anfang']);
  });
}
