import 'package:drift/drift.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/id/id_generator.dart';
import '../../../core/time/clock.dart';
import '../../../data/database/app_database.dart';
import '../domain/tag.dart';

class DriftTagRepository implements TagRepository {
  DriftTagRepository(this._db, {required this._clock, required this._ids});

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  $TagsTable get _tags => _db.tags;
  $EntryTagsTable get _entryTags => _db.entryTags;

  @override
  Stream<List<Tag>> watchTags() {
    final count = _entryTags.entryId.count();
    final query =
        _db.select(_tags).join([
            leftOuterJoin(
              _entryTags,
              _entryTags.tagId.equalsExp(_tags.id),
              useColumns: false,
            ),
          ])
          ..addColumns([count])
          ..groupBy([_tags.id])
          ..orderBy([OrderingTerm.asc(_tags.nameKey)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          _toDomain(row.readTable(_tags), row.read(count) ?? 0),
      ],
    );
  }

  @override
  Stream<List<Tag>> watchEntryTags(String entryId) {
    final query =
        _db.select(_tags).join([
            innerJoin(_entryTags, _entryTags.tagId.equalsExp(_tags.id)),
          ])
          ..where(_entryTags.entryId.equals(entryId))
          ..orderBy([OrderingTerm.asc(_tags.nameKey)]);
    return query.watch().map(
      (rows) => [for (final row in rows) _toDomain(row.readTable(_tags))],
    );
  }

  @override
  Future<Tag> createTag(String name) async {
    final cleaned = TagNames.validate(name);
    return _guard('createTag', () {
      return _db.transaction(() async {
        await _throwIfTaken(cleaned);
        final now = _clock.nowUtc();
        final id = _ids.newId();
        await _db
            .into(_tags)
            .insert(
              TagsCompanion.insert(
                id: id,
                name: cleaned,
                nameKey: TagNames.key(cleaned),
                createdAt: now,
                updatedAt: now,
              ),
            );
        return Tag(id: id, name: cleaned);
      });
    });
  }

  @override
  Future<Tag> renameTag(String id, String name) async {
    final cleaned = TagNames.validate(name);
    return _guard('renameTag', () {
      return _db.transaction(() async {
        await _throwIfTaken(cleaned, exceptId: id);
        final updated = await (_db.update(_tags)..where((t) => t.id.equals(id)))
            .write(
              TagsCompanion(
                name: Value(cleaned),
                nameKey: Value(TagNames.key(cleaned)),
                updatedAt: Value(_clock.nowUtc()),
              ),
            );
        if (updated == 0) throw NotFoundException('Tag', id);
        return Tag(id: id, name: cleaned);
      });
    });
  }

  @override
  Future<void> deleteTag(String id) => _guard('deleteTag', () async {
    // Assignments go with the tag (foreign key cascade).
    await (_db.delete(_tags)..where((t) => t.id.equals(id))).go();
  });

  @override
  Future<void> setEntryTags(String entryId, Set<String> tagIds) => _guard(
    'setEntryTags',
    () {
      return _db.transaction(() async {
        final entry = await (_db.select(
          _db.vocabularyEntries,
        )..where((e) => e.id.equals(entryId))).getSingleOrNull();
        if (entry == null) throw NotFoundException('VocabularyEntry', entryId);
        await (_db.delete(
          _entryTags,
        )..where((et) => et.entryId.equals(entryId))).go();
        final now = _clock.nowUtc();
        await _db.batch(
          (batch) => batch.insertAll(_entryTags, [
            for (final tagId in tagIds)
              EntryTagsCompanion.insert(
                entryId: entryId,
                tagId: tagId,
                createdAt: now,
              ),
          ]),
        );
      });
    },
  );

  @override
  Future<Map<String, List<String>>> getTagNamesForDeck(String deckId) =>
      _guard('getTagNamesForDeck', () async {
        final query =
            _db.select(_entryTags).join([
                innerJoin(_tags, _tags.id.equalsExp(_entryTags.tagId)),
                innerJoin(
                  _db.vocabularyEntries,
                  _db.vocabularyEntries.id.equalsExp(_entryTags.entryId),
                ),
              ])
              ..where(_db.vocabularyEntries.deckId.equals(deckId))
              ..orderBy([OrderingTerm.asc(_tags.nameKey)]);
        final result = <String, List<String>>{};
        for (final row in await query.get()) {
          (result[row.readTable(_entryTags).entryId] ??= []).add(
            row.readTable(_tags).name,
          );
        }
        return result;
      });

  Future<void> _throwIfTaken(String name, {String? exceptId}) async {
    final existing = await (_db.select(
      _tags,
    )..where((t) => t.nameKey.equals(TagNames.key(name)))).getSingleOrNull();
    if (existing != null && existing.id != exceptId) {
      throw const TagValidationException(TagValidationError.nameDuplicate);
    }
  }

  static Tag _toDomain(TagRow row, [int entryCount = 0]) =>
      Tag(id: row.id, name: row.name, entryCount: entryCount);

  Future<T> _guard<T>(String operation, Future<T> Function() body) async {
    try {
      return await body();
    } on AppException {
      rethrow;
    } on Object catch (error, stackTrace) {
      throw StorageException(operation, error, stackTrace);
    }
  }
}

/// Adds the tags named [names] to [entryId], creating tags that do not
/// exist yet (matched by [TagNames.key]). Existing assignments are kept.
/// Must run inside the caller's transaction (used by imports).
Future<void> addTagsByName(
  AppDatabase db,
  String entryId,
  Iterable<String> names, {
  required DateTime now,
  required IdGenerator ids,
}) async {
  for (final name in names) {
    final cleaned = TagNames.clean(name);
    if (cleaned.isEmpty || cleaned.length > TagNames.maxLength) continue;
    final key = TagNames.key(cleaned);
    var tag = await (db.select(
      db.tags,
    )..where((t) => t.nameKey.equals(key))).getSingleOrNull();
    if (tag == null) {
      final id = ids.newId();
      await db
          .into(db.tags)
          .insert(
            TagsCompanion.insert(
              id: id,
              name: cleaned,
              nameKey: key,
              createdAt: now,
              updatedAt: now,
            ),
          );
      tag = TagRow(
        id: id,
        name: cleaned,
        nameKey: key,
        createdAt: now,
        updatedAt: now,
      );
    }
    await db
        .into(db.entryTags)
        .insert(
          EntryTagsCompanion.insert(
            entryId: entryId,
            tagId: tag.id,
            createdAt: now,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }
}
