import 'package:ai_wortbox/core/config/app_config.dart';
import 'package:ai_wortbox/core/language/language.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Language', () {
    test('defaults are German source and Persian definitions', () {
      expect(AppConfig.defaultSourceLanguage, Language.german);
      expect(AppConfig.defaultDefinitionLanguage, Language.persian);
      expect(Language.german.code, 'de');
      expect(Language.persian.code, 'fa');
    });

    test('Persian is right-to-left, German is not', () {
      expect(Language.persian.isRightToLeft, isTrue);
      expect(Language.german.isRightToLeft, isFalse);
    });

    test('fromCode resolves known codes case-insensitively', () {
      expect(Language.fromCode('DE'), same(Language.german));
      expect(Language.fromCode(' fa '), same(Language.persian));
    });

    test('fromCode preserves unknown codes instead of throwing', () {
      final language = Language.fromCode('tr');
      expect(language.code, 'tr');
      expect(language.isSupported, isFalse);
      expect(language, const Language.unknown('tr'));
    });
  });
}
