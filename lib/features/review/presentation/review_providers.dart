import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/review_direction.dart';

/// The learner's review direction, stored in `app_settings`. German →
/// Persian until the learner chooses otherwise.
class ReviewDirectionController extends AsyncNotifier<ReviewDirection> {
  @override
  Future<ReviewDirection> build() async => ReviewDirection.parse(
    await ref.read(settingsStoreProvider).read(ReviewDirection.settingsKey),
  );

  /// Saves [direction]; the state changes only after the write succeeded.
  Future<void> set(ReviewDirection direction) async {
    await ref.read(settingsStoreProvider).writeAll({
      ReviewDirection.settingsKey: direction.name,
    });
    state = AsyncData(direction);
  }
}

final reviewDirectionProvider =
    AsyncNotifierProvider<ReviewDirectionController, ReviewDirection>(
      ReviewDirectionController.new,
    );

/// Cards due now for the chosen direction, in one deck or (null) all decks.
final dueCountProvider = StreamProvider.autoDispose.family<int, String?>((
  ref,
  deckId,
) async* {
  final direction = await ref.watch(reviewDirectionProvider.future);
  yield* ref
      .watch(studyRepositoryProvider)
      .watchDueCount(deckId: deckId, directions: direction.cardDirections);
});
