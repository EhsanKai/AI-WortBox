# Backup file format (version 1)

Settings → Backup and restore saves one UTF-8 JSON file (`AI WortBox -
backup - YYYY-MM-DD.json`). It is created on the device and saved where the
user chooses; it is never uploaded. It is **not encrypted**.

## Structure

```json
{
  "format": "ai-wortbox-backup",
  "formatVersion": 1,
  "exportedAt": "2026-10-20T12:00:00.000Z",
  "app": {"version": "1.0.0", "build": "3"},
  "schemaVersion": 3,
  "counts": {"decks": 2, "entries": 3, "meanings": 3, "flashcards": 3,
             "tags": 1, "entryTags": 1, "reviewEvents": 6,
             "sentencePractice": 1},
  "checksum": {"algorithm": "sha256", "value": "…"},
  "data": {
    "decks": [], "entries": [], "meanings": [], "flashcards": [],
    "tags": [], "entryTags": [], "reviewEvents": [], "sentencePractice": []
  }
}
```

- `formatVersion` is independent of the database `schemaVersion`; the file
  records both. A file with a higher format version or schema version than
  the app supports is rejected.
- `checksum.value` is the SHA-256 of `jsonEncode(data)` (the data object
  re-encoded as compact JSON in file order). A changed or damaged file is
  rejected.
- All times are UTC ISO-8601 with `Z`; enums are stored by name, as in the
  database.

## Contents

| List | Fields (one object per row) |
| --- | --- |
| `decks` | id, name, sourceLanguage, definitionLanguage, dailyNewCardLimit, createdAt, updatedAt |
| `entries` | id, deckId, original, normalized, lemma, sourceLanguage, definitionLanguage, partOfSpeech, exampleSentence, exampleTranslation, grammarInfo, notes, sourceContext, sourceType, enrichmentStatus, enrichmentMetadata (JSON text), userEditedAt, markedDifficultAt, createdAt, updatedAt |
| `meanings` | id, entryId, position, meaning, explanation |
| `flashcards` | id, entryId, direction, state, step, stability, difficulty, due, lastReviewedAt, reviewCount, lapseCount, schedulerVersion, createdAt, updatedAt — the complete FSRS state |
| `tags` | id, name, createdAt, updatedAt (the case-insensitive key is recomputed) |
| `entryTags` | entryId, tagId, createdAt |
| `reviewEvents` | id, entryId (null for a deleted word: history is kept), sessionId, direction, outcome, reviewedAt, localDay |
| `sentencePractice` | id, entryId, direction, level, outcome, practicedAt |

**Not included:** the OpenRouter API key (it lives only in OS secure
storage and is never read for a backup) and everything in `app_settings`:
AI preferences (free-only mode, routing, words per request), free-usage
counters, the AI result cache and unfinished AI runs, the study reminder
and the review direction. These are device settings; a restore never
changes them. `search_key` is derived and recomputed on restore.

## Validation (before anything is written)

The whole file is checked first; any problem rejects it with a localized
message and nothing changes: not JSON or not this format; unsupported
format version or newer schema; checksum mismatch; missing required
fields; wrong types, enum names, dates (must be UTC), ranges (deck limit
0–1000, name lengths, counts ≥ 0, a real calendar `localDay`), invalid
`enrichmentMetadata`; duplicate ids or unique values (deck names and tag
names case-insensitively, meaning positions per word, one card per word and
direction, tag assignments); references to decks, words or tags missing
from the file; `counts` not matching the lists; files over 100 MB. Files
above 256 KB are validated on a background isolate.

## Restore

Both modes first save the current data as a **safety copy** (same format)
in the app's private support directory (the newest three are kept); if that
fails, nothing is restored. Both then run in **one database transaction**:
a failure rolls everything back.

- **Add to my current data (merge):** adds what the device does not have.
  Records are matched by id; a deck also by name, a tag by name, and a word
  also by the app's duplicate rule (same word in the same deck with no new
  meaning). Nothing on the device is changed or deleted. A word that is
  already on the device keeps its content and its own FSRS state (the
  backup's card is not applied); tag assignments and review history are
  added. Review and sentence-practice events already present (same id) are
  not duplicated.
- **Replace all my data:** after an explicit confirmation dialog, deletes
  all decks, words, meanings, cards, tags, review and sentence-practice
  history on the device and inserts the backup's records with their ids.
  Settings are kept. The safety copy can be restored from the same screen.
