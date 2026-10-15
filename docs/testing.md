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
| `test/features/vocabulary/domain/vocabulary_draft_test.dart` | Cleaning (whitespace, blank/repeated meanings, notes), validation limits |
| `test/features/vocabulary/domain/duplicate_detection_test.dart` | Redundant vs. different-meaning duplicates, edit exclusion, `planImport` for all strategies incl. in-file merges, determinism, non-destructive merge |
| `test/features/vocabulary/data/drift_vocabulary_repository_test.dart` | CRUD, meaning order, Persian round-trip, status transitions, `userEditedAt`, review state untouched by update/merge, cascade delete, reactive stream, import per strategy, **rollback on mid-import failure**, 2,000-row import, persistence across reopen |
| `test/features/csv_import/data/csv_parser_test.dart` | UTF-8/BOM/UTF-16, rejection of Latin-1, NUL and empty files, size and row limits, quotes/escapes/multi-line cells, line endings, line numbers, unterminated quotes, delimiter detection and `sep=` |
| `test/features/csv_import/domain/column_mapping_test.dart` | English/German/Persian header recognition, mapping suggestions with and without header, mapping edits |
| `test/features/csv_import/domain/csv_import_analysis_test.dart` | Meaning splitting, all fixtures end-to-end, row errors with line numbers, strategy counts, swapped-language detection, header toggle |
| `test/widgets/vocabulary_flow_test.dart` | Add → view → edit → delete via UI (LTR German fields, review state kept), duplicate dialogs, "save & add next", search |
| `test/widgets/csv_import_flow_test.dart` | Pick file → preview → confirm languages → import → result → deck; row errors; broken file |

### CSV fixtures (`test/fixtures/csv/`)

`basic_comma.csv` (CRLF, quoted commas, multi-line cell), `excel_semicolon_bom.csv`,
`tab_no_header.tsv`, `persian_headers.csv`, `malformed_rows.csv`,
`duplicates.csv`, `unterminated_quote.csv`, `latin1.csv` (must be rejected),
`utf16le_bom.txt`, `persian_first.csv`, `sep_hint.csv`. `.gitattributes`
marks them `-text` so Git never changes their bytes.

## Phase 2 results (2026-10-15)

- `dart format --set-exit-if-changed lib test`: 74 files, 0 changed
- `flutter analyze`: no issues
- `flutter test`: **136 passed, 0 failed** (50 from Phase 1, 86 new)
- `flutter build apk --debug`: not possible — "No Android SDK found"
- `flutter build ios --debug --no-codesign`: not possible — "Application not
  configured for iOS" (no full Xcode)

## Phase 1 results (2026-10-15)

- `dart format --set-exit-if-changed`: 0 files changed
- `flutter analyze`: no issues
- `flutter test`: **50 passed, 0 failed**

## Not yet verified in this environment

- Running on an iOS simulator/device or Android emulator/device: the
  development machine has no Android SDK and no full Xcode installation.
  `flutter build apk` and `flutter build ios` could not run.
- Real restart persistence on a device (covered on the host by file-backed
  reopen tests for decks and entries).
- The native file picker on iOS/Android (tests use a fake file source).
- Persian keyboard input and rendering on real devices (widget tests verify
  text direction, not glyph shaping).

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

## Manual verification checklist (Phase 2)

1. **Add manually:** افزودن لغت → افزودن دستی. Save with an empty word: an
   inline error appears. Enter `Bank`, meaning `بانک`, add a second meaning
   `نیمکت`, open «جزئیات بیشتر», add an example. Save.
2. The German field types left-to-right and the Persian fields right-to-left.
3. Open the deck: `Bank` appears with «بانک، نیمکت». Open it: meanings,
   example and status «آماده» are shown.
4. **Edit:** change a meaning and save; the detail screen updates.
5. **Duplicates:** add `bank` with `بانک`: a dialog says it already exists
   (offers to open it). Add `Bank` with `ساحل`: the dialog offers to add the
   meaning or save a separate word. Choose "add"; only one `Bank` remains,
   now with three meanings.
6. **Search:** search for `نیمکت` and for `BAN`.
7. **Delete:** delete a word; a warning mentions review history; it
   disappears from the list.
8. **CSV:** save the example from README as UTF-8 CSV (also try "CSV UTF-8"
   from Excel, which adds a BOM and may use `;`). Import it via the deck's
   import button. Check the detected delimiter/encoding, column mapping,
   preview counts, and that Import is disabled until the language checkbox
   is ticked. Import, then open the deck.
9. Import the same file again: all rows are reported as duplicates and
   nothing new is created.
10. Import a file with an empty word cell: the row is listed with its line
    number and skipped; other rows import.
11. Try a Latin-1/Windows-encoded CSV: a clear encoding error appears.
12. Force-quit and relaunch: words and meanings are still there.
13. Turn on airplane mode: all of the above still works.
