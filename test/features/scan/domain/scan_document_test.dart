import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/features/scan/domain/scan_document.dart';
import 'package:ai_wortbox/features/scan/domain/scan_review_item.dart';
import 'package:ai_wortbox/features/scan/domain/scan_text.dart';
import 'package:ai_wortbox/features/scan/domain/text_tokenizer.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

ScanDocument doc(String text) => ScanDocument(ScanText.typed(text));

TextToken word(ScanDocument d, String display, [int occurrence = 0]) =>
    d.words.where((w) => w.display == display).elementAt(occurrence);

void main() {
  const page =
      'Sie gab sich große Mühe, das Ver-\nständnis zu fördern.\n\n'
      'Am nächsten Tag ging sie nach Hause.';

  test('splits paragraphs at blank lines', () {
    final d = doc(page);
    expect(d.paragraphs, hasLength(2));
    expect(d.hasWords, isTrue);
    expect(doc(' 12 34 !').hasWords, isFalse);
  });

  test('single word: text, original spelling and sentence context', () {
    final d = doc(page);
    final range = d.rangeOfWord(word(d, 'Verständnis'));
    expect(d.selectedText(range), 'Verständnis');
    expect(
      d.contextOf(range),
      'Sie gab sich große Mühe, das Verständnis zu fördern.',
    );
  });

  test('multi-word expression keeps inner words and order', () {
    final d = doc(page);
    final range = d.rangeBetween(
      word(d, 'Mühe'),
      word(d, 'sich'),
      maxWords: 10,
    )!;
    expect(d.selectedText(range), 'sich große Mühe');
  });

  test('expressions are limited in length and to one paragraph', () {
    final d = doc(page);
    expect(
      d.rangeBetween(word(d, 'Sie'), word(d, 'fördern'), maxWords: 5),
      isNull,
    );
    expect(
      d.rangeBetween(word(d, 'fördern'), word(d, 'Am'), maxWords: 10),
      isNull,
    );
  });

  test('review item turns into a vocabulary draft from the image source', () {
    final d = doc(page);
    final range = d.rangeOfWord(word(d, 'ging'));
    final item = ScanReviewItem(
      id: 1,
      original: d.selectedText(range),
      context: d.contextOf(range),
      lemma: 'gehen',
      meaning: 'رفت؛ رفتن',
    );
    final draft = item.toDraft('deck');
    expect(draft.original, 'ging');
    expect(draft.lemma, 'gehen');
    expect(draft.sourceContext, 'Am nächsten Tag ging sie nach Hause.');
    expect(draft.sourceType, VocabularySourceType.image);
    expect(draft.meanings.map((m) => m.text), ['رفت', 'رفتن']);
    expect(Language.german.code, 'de');
  });

  test('correcting the word updates the base-form hint', () {
    const item = ScanReviewItem(id: 1, original: 'gmg', context: '');
    expect(item.hint, isNull);
    expect(item.copyWith(original: 'ging').hint?.baseForm, 'gehen');
  });
}
