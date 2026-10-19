import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../domain/tag.dart';

/// All tags with their entry counts, alphabetically.
final tagsProvider = StreamProvider<List<Tag>>(
  (ref) => ref.watch(tagRepositoryProvider).watchTags(),
);

/// The tags of one entry.
final entryTagsProvider = StreamProvider.family<List<Tag>, String>(
  (ref, entryId) => ref.watch(tagRepositoryProvider).watchEntryTags(entryId),
);
