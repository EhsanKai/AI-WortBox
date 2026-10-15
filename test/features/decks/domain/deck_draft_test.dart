import 'package:ai_wortbox/core/config/app_config.dart';
import 'package:ai_wortbox/core/error/app_exception.dart';
import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/features/decks/domain/deck.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DeckDraft', () {
    test('defaults to German → Persian and the default daily limit', () {
      const draft = DeckDraft(name: 'A1');
      expect(draft.sourceLanguage, Language.german);
      expect(draft.definitionLanguage, Language.persian);
      expect(draft.dailyNewCardLimit, AppConfig.defaultDailyNewCardLimit);
      expect(draft.validate(), isEmpty);
    });

    test('cleans the name for storage', () {
      expect(
        const DeckDraft(name: '  Der   Vorleser ').cleanedName,
        'Der Vorleser',
      );
    });

    test('rejects empty and whitespace-only names', () {
      expect(const DeckDraft(name: '').validate(), {
        DeckValidationError.nameEmpty,
      });
      expect(const DeckDraft(name: '   ').validate(), {
        DeckValidationError.nameEmpty,
      });
    });

    test('limits name length by characters, including Persian', () {
      final ok = DeckDraft(name: 'ب' * AppConfig.maxDeckNameLength);
      final tooLong = DeckDraft(name: 'ب' * (AppConfig.maxDeckNameLength + 1));
      expect(ok.validate(), isEmpty);
      expect(tooLong.validate(), {DeckValidationError.nameTooLong});
    });

    test('validates the daily new-card limit bounds', () {
      expect(
        const DeckDraft(name: 'x', dailyNewCardLimit: 0).validate(),
        isEmpty,
      );
      expect(
        const DeckDraft(
          name: 'x',
          dailyNewCardLimit: AppConfig.maxDailyNewCardLimit,
        ).validate(),
        isEmpty,
      );
      expect(const DeckDraft(name: 'x', dailyNewCardLimit: -1).validate(), {
        DeckValidationError.dailyLimitOutOfRange,
      });
      expect(
        const DeckDraft(
          name: 'x',
          dailyNewCardLimit: AppConfig.maxDailyNewCardLimit + 1,
        ).validate(),
        {DeckValidationError.dailyLimitOutOfRange},
      );
    });

    test('rejects unsupported and identical languages', () {
      expect(
        const DeckDraft(
          name: 'x',
          sourceLanguage: Language.unknown('tr'),
        ).validate(),
        {DeckValidationError.unsupportedLanguage},
      );
      expect(
        const DeckDraft(
          name: 'x',
          definitionLanguage: Language.german,
        ).validate(),
        {DeckValidationError.identicalLanguages},
      );
    });
  });
}
