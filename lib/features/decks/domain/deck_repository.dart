import 'deck.dart';

/// Persistence boundary for decks.
///
/// Implementations throw [DeckValidationException] for invalid input and
/// [StorageException] for database failures.
abstract interface class DeckRepository {
  /// All decks with entry counts, newest first. Emits again on every change.
  Stream<List<DeckSummary>> watchDeckSummaries();

  /// A single deck, or `null` when it does not exist (e.g. was deleted).
  Stream<Deck?> watchDeck(String id);

  Future<List<Deck>> getDecks();

  Future<Deck?> getDeck(String id);

  /// Validates [draft], rejects case-insensitive duplicate names and inserts
  /// the deck in a single transaction.
  Future<Deck> createDeck(DeckDraft draft);
}
