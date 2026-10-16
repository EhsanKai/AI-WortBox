import 'package:ai_wortbox/core/config/app_config.dart';
import 'package:ai_wortbox/features/scan/domain/sentence_context.dart';
import 'package:flutter_test/flutter_test.dart';

String contextOf(String text, String word) {
  final start = text.indexOf(word);
  return SentenceContext.around(text, start, start + word.length);
}

void main() {
  test('returns the sentence containing the selection', () {
    const text = 'Ich lese ein Buch. Das Haus ist alt! Wohnst du hier?';
    expect(contextOf(text, 'Haus'), 'Das Haus ist alt!');
    expect(contextOf(text, 'Buch'), 'Ich lese ein Buch.');
    expect(contextOf(text, 'hier'), 'Wohnst du hier?');
  });

  test('joins lines and hyphenated line breaks', () {
    const text =
        'Er hatte kein Ver-\nständnis für die\nSituation. Danach ging er.';
    expect(
      contextOf(text, 'Situation'),
      'Er hatte kein Verständnis für die Situation.',
    );
  });

  test('does not split at abbreviations, ordinals or initials', () {
    const text =
        'Wir treffen z. B. Dr. Müller am 3. Mai in der Stadt. Dann essen wir.';
    expect(
      contextOf(text, 'Stadt'),
      'Wir treffen z. B. Dr. Müller am 3. Mai in der Stadt.',
    );
  });

  test('keeps closing quotes and stops at paragraph breaks', () {
    const text = 'Titel ohne Punkt\n\n„Komm her!“ rief sie. Er kam.';
    expect(contextOf(text, 'Komm'), '„Komm her!“');
    expect(contextOf(text, 'Titel'), 'Titel ohne Punkt');
  });

  test('an expression spanning two sentences gets both', () {
    const text = 'Eins zwei. Drei vier. Fünf.';
    final start = text.indexOf('zwei');
    final end = text.indexOf('Drei') + 4;
    expect(SentenceContext.around(text, start, end), 'Eins zwei. Drei vier.');
  });

  test('shortens very long sentences around the selection', () {
    final long =
        '${List.filled(150, 'Wort').join(' ')} Ziel ${List.filled(150, 'Wort').join(' ')}.';
    final context = contextOf(long, 'Ziel');
    expect(context.length, lessThanOrEqualTo(AppConfig.maxContextLength + 2));
    expect(context, startsWith('…'));
    expect(context, endsWith('…'));
    expect(context, contains('Ziel'));
  });
}
