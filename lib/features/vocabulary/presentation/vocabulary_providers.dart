import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/vocabulary_entry.dart';
import '../domain/vocabulary_search.dart';

final deckEntriesProvider =
    StreamProvider.family<List<VocabularyEntry>, String>(
      (ref, deckId) =>
          ref.watch(vocabularyRepositoryProvider).watchEntries(deckId),
    );

final entryProvider = StreamProvider.family<VocabularyEntry?, String>(
  (ref, id) => ref.watch(vocabularyRepositoryProvider).watchEntry(id),
);

/// Entries matching a search and filters (runs in the database).
final vocabularySearchProvider = StreamProvider.autoDispose
    .family<List<VocabularyEntry>, VocabularyQuery>(
      (ref, query) =>
          ref.watch(vocabularyRepositoryProvider).watchSearch(query),
    );

/// Number of entries and of difficult entries in all decks.
final vocabularyCountsProvider = StreamProvider<({int total, int difficult})>(
  (ref) => ref.watch(vocabularyRepositoryProvider).watchCounts(),
);
