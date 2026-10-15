import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime.utc(2026, 10, 15, 8);

  VocabularyEntry entry({
    String original = 'aufgeben',
    List<VocabularyMeaning> meanings = const [],
  }) => VocabularyEntry(
    id: 'e1',
    deckId: 'd1',
    original: original,
    normalized: original.toLowerCase(),
    sourceLanguage: Language.german,
    definitionLanguage: Language.persian,
    sourceType: VocabularySourceType.manual,
    enrichmentStatus: EnrichmentStatus.missing,
    createdAt: created,
    updatedAt: created,
    meanings: meanings,
  );

  test('supports multiple ordered meanings', () {
    final e = entry(
      meanings: const [
        VocabularyMeaning('تسلیم شدن'),
        VocabularyMeaning('ترک کردن', explanation: 'مثلاً ترک سیگار'),
      ],
    );
    expect(e.hasMeanings, isTrue);
    expect(e.meanings.first.text, 'تسلیم شدن');
    expect(e.meanings[1].explanation, 'مثلاً ترک سیگار');
  });

  test('detects multi-word expressions', () {
    expect(entry(original: 'sich Mühe geben').isMultiWordExpression, isTrue);
    expect(entry(original: 'Haus').isMultiWordExpression, isFalse);
  });

  test('value equality includes meanings', () {
    expect(
      entry(meanings: const [VocabularyMeaning('خانه')]),
      entry(meanings: const [VocabularyMeaning('خانه')]),
    );
    expect(
      entry(meanings: const [VocabularyMeaning('خانه')]),
      isNot(entry(meanings: const [VocabularyMeaning('منزل')])),
    );
  });

  test('enum names are stable because they are persisted', () {
    expect(VocabularySourceType.values.map((v) => v.name), [
      'manual',
      'csv',
      'image',
    ]);
    expect(EnrichmentStatus.values.map((v) => v.name), [
      'missing',
      'pending',
      'ready',
      'failed',
    ]);
  });

  test('EnrichmentMetadata round-trips through JSON in UTC', () {
    final metadata = EnrichmentMetadata(
      provider: 'openrouter',
      model: 'some/model',
      generatedAt: DateTime.utc(2026, 1, 2, 3, 4, 5),
      isAmbiguous: true,
    );
    expect(EnrichmentMetadata.fromJson(metadata.toJson()), metadata);
  });
}
