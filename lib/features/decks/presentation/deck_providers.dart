import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/deck.dart';

final deckSummariesProvider = StreamProvider<List<DeckSummary>>(
  (ref) => ref.watch(deckRepositoryProvider).watchDeckSummaries(),
);

final deckProvider = StreamProvider.family<Deck?, String>(
  (ref, id) => ref.watch(deckRepositoryProvider).watchDeck(id),
);
