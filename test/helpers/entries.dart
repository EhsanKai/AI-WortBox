import 'package:ai_wortbox/core/language/language.dart';
import 'package:ai_wortbox/core/text/text_normalizer.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_draft.dart';
import 'package:ai_wortbox/features/vocabulary/domain/vocabulary_entry.dart';

/// An in-memory entry for pure domain tests.
VocabularyEntry testEntry(
  String id,
  String original,
  List<String> meanings, {
  String deckId = 'deck',
  int minute = 0,
}) {
  final at = DateTime.utc(2026, 1, 1, 0, minute);
  return VocabularyEntry(
    id: id,
    deckId: deckId,
    original: original,
    normalized: TextNormalizer.vocabularyKey(original),
    sourceLanguage: Language.german,
    definitionLanguage: Language.persian,
    sourceType: VocabularySourceType.manual,
    enrichmentStatus: meanings.isEmpty
        ? EnrichmentStatus.missing
        : EnrichmentStatus.ready,
    createdAt: at,
    updatedAt: at,
    meanings: [for (final m in meanings) VocabularyMeaning(m)],
  );
}

VocabularyDraft testDraft(
  String original,
  List<String> meanings, {
  String deckId = 'deck',
}) => VocabularyDraft(
  deckId: deckId,
  original: original,
  meanings: [for (final m in meanings) VocabularyMeaning(m)],
).cleaned();
