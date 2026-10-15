# Testing

## Commands

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Tests run on the host Dart VM. The database tests use the SQLite library
bundled by `package:sqlite3` (no device needed).

## Suites

| File | Covers |
| --- | --- |
| `test/core/language_test.dart` | Default language pair, RTL flags, code resolution, unknown codes |
| `test/core/text_normalizer_test.dart` | Whitespace, umlaut composition, Persian letter unification, vocabulary keys |
| `test/features/decks/domain/deck_draft_test.dart` | Deck defaults and validation rules |
| `test/features/vocabulary/domain/vocabulary_entry_test.dart` | Multiple meanings, expressions, equality, persisted enum names, metadata JSON |
| `test/features/review/domain/flashcard_test.dart` | Initial review state, persisted enum names |
| `test/data/database/app_database_test.dart` | Schema v1 tables, foreign keys, CHECK/UNIQUE constraints, Persian Unicode round-trip, cascade deletes, content edits not touching review state, UTC storage |
| `test/drift/app_database/schema_test.dart` | Created schema equals exported `drift_schema_v1.json` |
| `test/features/decks/data/drift_deck_repository_test.dart` | Create/list/get, defaults, cleaning, ordering, validation, Unicode-aware duplicate names, reactive streams, `StorageException` wrapping, persistence across a database reopen (file-backed) |
| `test/widgets/app_test.dart` | App launches in Persian RTL, five tabs, Add screen actions, create-deck flow, validation and duplicate errors |

## Phase 1 results (2026-10-15)

- `dart format --set-exit-if-changed`: 0 files changed
- `flutter analyze`: no issues
- `flutter test`: **50 passed, 0 failed**

## Not yet verified in this environment

- Running on an iOS simulator/device or Android emulator/device: the
  development machine has no Android SDK and no full Xcode installation.
  `flutter build apk` and `flutter build ios` could not run.
- Real restart persistence on a device (covered on the host by a file-backed
  reopen test).

## Manual verification checklist (Phase 1)

1. `flutter run` on a device. The app opens on **مرور امروز** with a
   right-to-left layout.
2. The bottom bar shows five tabs: مرور امروز, لغات من, افزودن لغت, آمار, تنظیمات.
3. Tap **ساخت دستهٔ جدید**. The form shows "Deutsch ← فارسی" and 20 new
   cards/day.
4. Submit with an empty name: an inline error appears.
5. Create "Der Vorleser". A confirmation appears; the deck is listed under
   **لغات من** with "بدون لغت".
6. Try to create "der vorleser". It is rejected as a duplicate.
7. Open the deck. Languages, daily limit and creation date are shown.
8. Kill and relaunch the app. The deck is still there.
9. Toggle system dark mode. The app follows it.
