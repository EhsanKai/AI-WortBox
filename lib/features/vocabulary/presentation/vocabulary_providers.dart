import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/vocabulary_entry.dart';

final deckEntriesProvider =
    StreamProvider.family<List<VocabularyEntry>, String>(
      (ref, deckId) =>
          ref.watch(vocabularyRepositoryProvider).watchEntries(deckId),
    );

final entryProvider = StreamProvider.family<VocabularyEntry?, String>(
  (ref, id) => ref.watch(vocabularyRepositoryProvider).watchEntry(id),
);
