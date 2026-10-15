import 'package:ai_wortbox/core/config/app_config.dart';
import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('cleaned', () {
    test('collapses whitespace but preserves spelling and case', () {
      final draft = const VocabularyDraft(
        deckId: 'd',
        original: '  sich   Mühe  geben ',
      ).cleaned();
      expect(draft.original, 'sich Mühe geben');
      expect(draft.normalized, 'sich mühe geben');
    });

    test('drops blank and repeated meanings, keeping order', () {
      final draft = const VocabularyDraft(
        deckId: 'd',
        original: 'Bank',
        meanings: [
          VocabularyMeaning(' بانک '),
          VocabularyMeaning('   '),
          VocabularyMeaning('نیمکت'),
          // Same as the first after normalization (Arabic yeh, tatweel).
          VocabularyMeaning('بـانک'),
        ],
      ).cleaned();
      expect(draft.meanings.map((m) => m.text), ['بانک', 'نیمکت']);
    });

    test('turns blank optional fields into null, keeps note line breaks', () {
      final draft = const VocabularyDraft(
        deckId: 'd',
        original: 'Haus',
        exampleSentence: '   ',
        grammarInfo: ' das,  -¨er ',
        notes: '  Zeile 1\nZeile 2  ',
      ).cleaned();
      expect(draft.exampleSentence, isNull);
      expect(draft.grammarInfo, 'das, -¨er');
      expect(draft.notes, 'Zeile 1\nZeile 2');
    });
  });

  group('validate', () {
    test('requires the word but not a meaning', () {
      expect(
        const VocabularyDraft(deckId: 'd', original: ' ').cleaned().validate(),
        {VocabularyValidationError.originalEmpty},
      );
      expect(
        const VocabularyDraft(
          deckId: 'd',
          original: 'Haus',
        ).cleaned().validate(),
        isEmpty,
      );
    });

    test('enforces length and count limits', () {
      expect(
        VocabularyDraft(
          deckId: 'd',
          original: 'a' * (AppConfig.maxOriginalLength + 1),
        ).validate(),
        {VocabularyValidationError.originalTooLong},
      );
      expect(
        VocabularyDraft(
          deckId: 'd',
          original: 'a',
          meanings: [VocabularyMeaning('ب' * (AppConfig.maxMeaningLength + 1))],
        ).validate(),
        {VocabularyValidationError.meaningTooLong},
      );
      expect(
        VocabularyDraft(
          deckId: 'd',
          original: 'a',
          meanings: [
            for (var i = 0; i <= AppConfig.maxMeaningsPerEntry; i++)
              VocabularyMeaning('m$i'),
          ],
        ).validate(),
        {VocabularyValidationError.tooManyMeanings},
      );
      expect(
        VocabularyDraft(
          deckId: 'd',
          original: 'a',
          notes: 'n' * (AppConfig.maxTextFieldLength + 1),
        ).validate(),
        {VocabularyValidationError.fieldTooLong},
      );
    });
  });
}
