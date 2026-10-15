import 'vocabulary_entry.dart';

/// Persistence boundary for vocabulary entries.
///
/// Declared in Phase 1 to fix the contract; the Drift implementation is
/// added in Phase 2 together with manual entry and CSV import.
abstract interface class VocabularyRepository {
  Stream<List<VocabularyEntry>> watchEntries(String deckId);

  Future<VocabularyEntry?> getEntry(String id);

  /// Entries in [deckId] whose normalized form equals [normalized]. Used for
  /// duplicate detection; several entries with distinct meanings may match.
  Future<List<VocabularyEntry>> findByNormalized(
    String deckId,
    String normalized,
  );

  Future<VocabularyEntry> saveEntry(VocabularyEntry entry);

  Future<void> deleteEntry(String id);
}
