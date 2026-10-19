import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/text/text_normalizer.dart';

/// A user-defined label for vocabulary entries.
@immutable
class Tag {
  const Tag({required this.id, required this.name, this.entryCount = 0});

  final String id;

  /// As entered, with whitespace cleaned up.
  final String name;

  /// Entries with this tag (only filled where counted).
  final int entryCount;

  @override
  bool operator ==(Object other) =>
      other is Tag &&
      other.id == id &&
      other.name == name &&
      other.entryCount == entryCount;

  @override
  int get hashCode => Object.hash(id, name, entryCount);

  @override
  String toString() => 'Tag($name)';
}

abstract final class TagNames {
  static const maxLength = AppConfig.maxTagNameLength;

  /// Display form: composed characters, single spaces, trimmed.
  static String clean(String name) => TextNormalizer.cleanName(name);

  /// Uniqueness key: case and repeated or edge spaces are ignored, so
  /// "B1" and " b1 " are the same tag; "b 1" is a different one.
  static String key(String name) => TextNormalizer.nameKey(name);

  /// Throws [TagValidationException] for an invalid name.
  static String validate(String name) {
    final cleaned = clean(name);
    if (cleaned.isEmpty) {
      throw const TagValidationException(TagValidationError.nameEmpty);
    }
    if (cleaned.length > maxLength) {
      throw const TagValidationException(TagValidationError.nameTooLong);
    }
    return cleaned;
  }

  /// Splits a tag cell from CSV/Anki import: `;`, `،`, `؛`, `|` or line
  /// breaks separate tags; blank parts are dropped and duplicates (by key)
  /// removed, first spelling wins.
  static List<String> split(String cell) {
    final seen = <String>{};
    return [
      for (final part in cell.split(RegExp(r'[;؛،|\n]')))
        if (clean(part) case final name
            when name.isNotEmpty &&
                name.length <= maxLength &&
                seen.add(key(name)))
          name,
    ];
  }
}

/// Manages tags and their assignment to entries. Never changes vocabulary
/// content or review state.
abstract interface class TagRepository {
  /// All tags, alphabetically, with their entry counts.
  Stream<List<Tag>> watchTags();

  /// Tags of one entry, alphabetically.
  Stream<List<Tag>> watchEntryTags(String entryId);

  /// Throws [TagValidationException] for an empty, too long or duplicate
  /// name.
  Future<Tag> createTag(String name);

  /// Throws like [createTag]; renaming to the same name with different case
  /// is allowed.
  Future<Tag> renameTag(String id, String name);

  /// Deletes the tag and its assignments. Entries are not changed.
  Future<void> deleteTag(String id);

  /// Replaces the tags of [entryId] with [tagIds].
  Future<void> setEntryTags(String entryId, Set<String> tagIds);

  /// Tag names per entry id for the entries of [deckId] (for exports).
  Future<Map<String, List<String>>> getTagNamesForDeck(String deckId);
}
