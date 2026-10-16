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

## Test requirements for upcoming and proposed work

Planning only. Tests for proposed features are written when, and only when,
the feature is approved.

### Phase 3 (approved)

- OCR adapter behind an interface; unit tests with a fake recognizer and
  recorded recognition results (no camera or ML model in automated tests).
- Tokenization and selection: single words, contiguous expressions,
  deselect/reset, selections stable when text is reflowed, punctuation and
  German quotes, hyphenated line breaks, umlauts and ß.
- Sentence-context extraction and lemma hints (conservative; original
  spelling preserved).
- Failure paths: permission denied, invalid image, OCR error, empty result,
  typed-text fallback; existing data unchanged after failures.
- Widget tests for selection, correction screen and saving only confirmed
  items.
- Manual device checks for real camera/gallery and German OCR accuracy, as
  soon as a toolchain is available.

### Schema migrations (whenever the schema changes)

- `make-migrations` generated tests for every version step.
- Data-preserving tests starting from realistic v1 data (decks, entries with
  several Persian meanings, flashcards) and verifying nothing is lost.

### Proposed features (only after approval)

| ID | Required tests |
| --- | --- |
| P1 | Search across decks, Persian/German normalization, filter combinations, performance with large collections |
| P2 | Tag CRUD, uniqueness, cascades, filter by tag, CSV tag column |
| P3 | Export → import round trip; backup → restore round trip preserving meanings order, tags, media, scheduling state and review history; rejection of corrupt, truncated, tampered (checksum) and future-version backups with no data change; preview counts; rollback on failure |
| P4 | Lemma/article matching, separable verbs, never merging distinct meanings |
| P5 | Multiple contexts/sources, migration of existing `source_context` |
| P6 | Fake TTS adapter; missing German voice handling |
| P7 | Fake notification scheduler; time zones/DST; permission denied |
| P8 | Streak and statistics calculations with an injected clock and day boundaries |
| P9 | Difficult-word detection thresholds; practice does not alter FSRS state unless decided otherwise |
| P10 | Independent forward/reverse scheduling; sibling handling |
| P11 | Structured grammar validation; migration keeps free-text grammar |
| P12 | Airplane-mode checks for words, decks, search and review |
| P13 | Media storage/deletion, backup inclusion, provider mocks (no paid calls in tests) |
| Anki | Fixtures from real Anki exports per supported version before any `.apkg` claim |

### Platform status

iOS and Android builds remain **unverified** (no Android SDK, no full
Xcode). This must be reported in every phase until real builds have run.

## Phase 3 results (2026-10-16)

- `dart format --set-exit-if-changed lib test`: 98 files, 0 changed
- `flutter analyze`: no issues
- `flutter test`: **189 passed, 0 failed** (136 from Phases 1–2 unchanged,
  53 new)
- `flutter build apk --debug`: not possible — "No Android SDK found"
- `flutter build ios --debug --no-codesign`: not possible — "Application not
  configured for iOS" (no full Xcode)

### Phase 3 suites

| File | Covers |
| --- | --- |
| `test/features/scan/domain/ocr_text_normalizer_test.dart` | Umlauts/ß/punctuation/quotes preserved, decomposed umlauts, ligatures, invisible characters, line endings; `ScanText` from OCR blocks (offsets, boxes), typed and edited text |
| `test/features/scan/domain/text_tokenizer_test.dart` | German word tokens, exact offsets, hyphenated line breaks (joined, kept hyphen, conjunction exception) |
| `test/features/scan/domain/sentence_context_test.dart` | Sentence boundaries, abbreviations/ordinals, quotes, paragraph breaks, multi-sentence selections, length limit |
| `test/features/scan/domain/word_selection_test.dart` | Toggle, overlap replacement, remapping after text correction |
| `test/features/scan/domain/lemma_hints_test.dart` | Listed irregular forms; no hint for ambiguous, regular, base or multi-word input |
| `test/features/scan/domain/scan_document_test.dart` | Paragraphs, word/expression text, expression limits, context, review item → draft (`image`, context, lemma, meanings), hint update after correction |
| `test/features/scan/data/scan_image_source_test.dart` | Format/size validation, `image_picker` error-code mapping |
| `test/features/scan/presentation/scan_controller_test.dart` | Pick/cancel/permission denied/unsupported image/OCR failure/OCR unavailable/empty result, photo always discarded, Android lost-image recovery, typed fallback, word and expression selection, deselect/reset, text correction, saving only reviewed items with corrections and context, duplicate handling and explicit merge, deck choice, failed save changes nothing |
| `test/widgets/scan_flow_test.dart` | Full UI flow from the Add tab (LTR text view, hint, correction, save, deck), permission denial message, empty result → typed fallback, existing word not saved again |

These tests use fakes for the camera/gallery and the OCR engine. They prove
the app logic and UI, **not** real camera, gallery or ML Kit behaviour.

## Manual device checklist (Phase 3)

Requires an Android device/emulator and an iPhone (iOS 15.5+; ML Kit may not
run on all iOS simulators).

1. Add Vocabulary → Scan a Book Page (or the scan icon in a deck). The intro
   says the photo stays on the device and that recognition can be wrong.
2. **Camera:** take a photo of a German book page. First use asks for camera
   permission (iOS shows the Persian/English usage text).
3. **Permission denied:** deny camera access; a clear message appears and the
   gallery and typing options still work. Re-allow in system settings.
4. **Gallery:** choose a JPEG, a PNG and an iPhone HEIC photo.
5. **Accuracy:** check umlauts (ä ö ü Ä Ö Ü), ß, „German quotes“, commas and
   line breaks against the page. Note typical OCR mistakes.
6. **Hyphenation:** a word split at a line end appears joined with a dotted
   underline.
7. **Selection:** tap single words; switch to «عبارت» and select a
   multi-word expression; tap again to deselect; clear all.
8. **Correction:** use «اصلاح متن», fix a misrecognized word; unrelated
   selections stay, changed ones are removed with a notice.
9. **Review:** the list shows exactly the selected items; edit a word, use a
   base-form hint (e.g. for "ging"), add an optional Persian meaning, check
   the original sentence.
10. **Save** to a chosen deck; open the deck and the entry: original form,
    sentence, base form and source «اسکن کتاب» are shown.
11. Scan the same page again and select a saved word: it is marked as already
    in the deck and is not saved twice.
12. **Empty/unreadable:** photograph a blank surface → "No text found" with
    retry and typing options. Try a very large panorama image.
13. **Typed fallback:** type/paste German text and save words from it.
14. **Android low memory:** enable "Don't keep activities" in developer
    options, take a photo; after returning, the recognized text should appear
    (lost-data recovery).
15. **Offline:** in airplane mode, OCR, selection and saving still work.
16. Check the device's photo/cache folders: no page photos are left behind
    by the app.
