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

## Phase 4 results (2026-10-17)

- `dart format --set-exit-if-changed lib test`: 0 changed
- `flutter analyze`: no issues
- `flutter test`: **358 passed, 2 skipped, 0 failed** (252 from earlier
  phases unchanged, 106 new). The 2 skipped tests are the opt-in live tests.
- No live OpenRouter request has been made; all AI tests use mocked HTTP
  (`package:http/testing.dart`) and an in-memory key store.
- Builds: still not possible on this machine (no Android SDK, no full
  Xcode).

### Phase 4 suites

| File | Covers |
| --- | --- |
| `test/features/enrichment/domain/enrichment_parser_test.dart` (18) | Valid structured output; code fences; non-JSON, truncated, wrong types, missing meanings; non-Persian meanings/explanations dropped; dedupe; meaning count/length limits; example/translation only as a valid pair; «» quotes, Persian digits, ZWNJ; lemma rules; part-of-speech mapping; control characters; strict schema |
| `test/features/enrichment/domain/enrichment_plan_test.dart` (11) | Defaults for entries without meanings; exact update contents; existing meanings protected (additions only, Persian letter variants, entry limit); filled fields only as non-default replacements; batch candidates and limit; request contains only word/context/meanings |
| `test/features/enrichment/data/openrouter_service_test.dart` (34) | Request URL, headers, body, structured-output routing, key only in `Authorization`; model selection; no key → no request; reported model/cost, no invented cost; malformed/truncated/no-choices; 200-with-error not retried; 400/401/402/403 not retried; 429/503 retried with backoff and `Retry-After` (capped); 402 with `Retry-After`; 408/500/502, network failures and client timeouts not retried (one request each); a later user retry sends a new request; retry classification; exceptions never contain the key; cancellation; `GET /key`; public model list sent without key |
| `test/features/enrichment/presentation/ai_settings_controller_test.dart` (15) | Save (trimmed), only last four characters in state, test result; malformed keys not saved; replace; remove; invalid key; offline; delisted/unknown model; no key → no request; catalog-only models; secure-storage read failure; failed save (unconfigured, no request), failed replacement (stored key shown), failed removal (still configured), failed model change (previous model kept), no key in errors |
| `test/features/vocabulary/data/apply_enrichments_test.dart` (8) | Fill and mark ready with metadata; existing meanings/user fields/`userEditedAt` kept; flashcards unchanged; conflict → nothing written; invalid update and deleted entry roll back the batch; duplicate meanings; empty list |
| `test/widgets/enrichment_flow_test.dart` (12) | Settings onboarding (explanation, link, hidden key, saved suffix, test, usage, remove); secure-storage save/remove failures shown with no success state and no key in messages; invalid and malformed keys; no key → setup prompt, no request; batch review/save with review state untouched; offline failure and user retry (one request each); timeout not repeated automatically, charge warning, user retry; invalid key stops the batch; insufficient credits; single entry with meanings (nothing preselected, other entries untouched); review screen at 320 px / 2× / dark |
| `test/widgets/design_system_test.dart` (+8) | AI settings and AI suggestions screens at 320 px, 1.5×/2×, light/dark |
| `test/live/openrouter_live_test.dart` (2, opt-in) | Real `GET /key` and one real enrichment; skipped unless `OPENROUTER_API_KEY` is set |

Every widget test runs with an HTTP client that fails on any request and an
in-memory key store, so no test can reach the network or the real Keychain/
Keystore.

Live check (spends a little of the key owner's credits; never commit keys):

```sh
OPENROUTER_API_KEY=sk-or-... flutter test test/live/openrouter_live_test.dart
```

## Manual device checklist (Phase 4)

Needs a real OpenRouter account with a small credit limit on the key,
Android and iPhone devices.

1. Settings → AI shows "Off"; the explanation says your own account pays.
   "Get a key" opens openrouter.ai/keys in the browser.
2. Enter a key: hidden by default, show/hide works, no keyboard suggestions.
   Save → "The key works", reported usage; status "On". Leave and return:
   only ••••last-four is shown.
3. Enter a wrong key → actionable error. Replace the key; remove it (with
   confirmation) → status "Off".
4. Choose each catalog model and test; note any "model not available".
5. Scan a page, save words without meanings; deck → AI suggestions → the
   screen says what is sent; start; review Persian meanings, example,
   grammar, base form; deselect some; save. Check the entries.
6. A word with meanings: AI suggestions from its page → nothing preselected;
   only new meanings offered; saving appends them.
7. Airplane mode → network message, nothing changed; the rest of the app
   works offline.
8. Key with exhausted limit → credits message, batch stops.
9. Stop a running batch; leave the screen mid-run → nothing saved.
   On a very slow connection, a timeout shows the "may have been charged"
   message and is not repeated until you tap "Retry failed items"; compare
   with the activity log on openrouter.ai.
10. Android: confirm `adb shell bmgr` backup excludes the key (restore on a
    new device → key absent, vocabulary present). iOS: reinstall → check
    whether the Keychain item persists; "Remove key" clears it.
11. Review states and due cards unchanged after enrichment (Phase 5 will
    show them; inspect the database if needed).

## Phase 5 results (2026-10-19)

- `dart format --set-exit-if-changed lib test`: 0 changed
- `flutter analyze`: no issues
- `flutter test`: **463 passed, 3 skipped, 0 failed** (baseline before
  Phase 5: 358 passed, 2 skipped). Skipped: the two opt-in OpenRouter live
  tests and the opt-in Anki sample writer (`ANKI_EXPORT_DIR`).
- The schema test that asserted "schema v1" was updated to v2 (expected
  change, not a weakened assertion).
- Anki compatibility (external, not part of `flutter test`): the app's
  `.apkg` export was imported by the official Anki library 26.09.3
  (`tool/anki/validate_apkg.py`): 2 new notes, 2 cards, every field and tag
  as expected, Anki's database check passed; re-importing reported 2
  duplicates and 0 new notes. Import fixtures were written by the same
  library (`tool/anki/make_fixtures.py`).
- Builds: still not possible on this machine (no Android SDK, no full
  Xcode). Nothing in Phase 5 has run on a device.

### What the automated tests can and cannot show

| Area | Automated (host) | Needs a real device |
| --- | --- | --- |
| Search, tags, difficult, export/import formats, statistics, migration | Real SQLite (in memory and on disk), real file formats | Performance with large collections |
| TTS | Method channel replaced: locale, voice check, error mapping | Whether a German voice exists, how it sounds, audio focus |
| Reminders | DST/next-time logic with real IANA data; controller with a fake scheduler | Permission prompts, delivery time, reboot/update restore, battery restrictions |
| File save | Fake sink: bytes, names, cancel, failure | System save dialogs, cloud providers, permissions |
| Anki | Fixtures written by Anki; export imported by the Anki library | Anki desktop GUI, AnkiDroid, AnkiMobile |

### Phase 5 suites

| File | Covers |
| --- | --- |
| `test/drift/app_database/migration_test.dart` (2) | Every schema step; v1 → v2 keeps decks, entries (Persian with Arabic letters and ZWNJ, metadata), meanings and flashcards unchanged, backfills search keys |
| `test/data/database/app_database_test.dart` (+2) | v2 tables; entry delete removes tag links, keeps tag and review history (entry reference nulled); unique tag key |
| `test/features/vocabulary/data/search_tags_difficult_test.dart` (14) | Search: empty/blank query, German case/umlaut/decomposed input, base form, Persian letter variants/diacritics/ZWNJ, no results, `%`/`_` literal, deck filter, limit, key updated on edit with stored text unchanged; difficult mark keeps content, `updatedAt` and flashcards; tags: validation, duplicates by case/spaces, rename, counts, filters, delete keeps words, entry delete; import tags only for created/merged rows; persistence after closing and reopening a database file |
| `test/features/export/csv_exporter_test.dart` (6) | Header, BOM, CRLF, empty list, quoting of quotes/commas/line breaks/edge spaces, round trip through the CSV importer with automatic mapping (German, Persian, tags), the `;`-in-meaning limitation, file names |
| `test/features/anki/anki_package_test.dart` (12, +1 opt-in) | HTML ↔ text; modern and legacy packages written by Anki (all note types, tags, HTML, sound, empty front); import analysis with duplicates; not a ZIP, no collection, damaged collection, placeholder-only package, no notes; export structure (schema 11, checksum equal to Anki's, escaping, cards, note type, deck); export → import round trip |
| `test/features/statistics/study_statistics_test.dart` (7) | Local days across month/leap/DST dates; empty state; several reviews per day; consecutive days; streak ending yesterday; missed day; longest streak; order independence |
| `test/features/review/data/drift_review_repository_test.dart` (4) | Local day from a UTC+3:30 offset around midnight; daily activity and distinct sessions; no writes to flashcards or vocabulary; empty history |
| `test/features/review/presentation/practice_controller_test.dart` (4) | Empty states; difficult-only; reveal required; double tap records once; reverse direction, one session; words and flashcards unchanged; 20-word cap |
| `test/features/reminders/reminder_test.dart` (12) | Next time today/tomorrow, Berlin autumn DST (25 h), spring-forward gap, Tehran; settings defaults and malformed values; permission denied (nothing saved); enable/reschedule/disable with one notification id; persistence across a new container; startup sync without permission prompt; scheduling and cancel failures |
| `test/features/speech/flutter_tts_speech_service_test.dart` (6) | `de-DE`, voice checked once, interruption, blank text, missing voice, engine errors, `stop` never throws |
| `test/widgets/phase5_flow_test.dart` (12) | Search across decks with deck names, no-result state, clear, difficult filter; mark difficult, pronounce, create tag (duplicate rejected), assign; missing voice message; tag filter; tag delete keeps word; practice → summary → streak on Today → statistics; narrow 320 px/2×/dark answer and statistics; difficult-only empty state; reminder permission denied/allowed/off; CSV and Anki export via the deck menu; cancelled/failed/empty export; Anki import from a real package through the preview; invalid package error |
| `test/widgets/design_system_test.dart` (+24) | Search, tags, Anki import, reminder, practice setup and session at 320 px, 1.5×/2×, light/dark |

## Manual device checklist (Phase 5)

Needs Android and iPhone devices; none of this has been run yet.

1. Update from a Phase 4 install with existing words: words, meanings and
   enrichment data are intact; search finds them by German and Persian.
2. Search: Persian with and without ZWNJ, German with umlauts; tag and
   difficult filters; clearing filters.
3. Tags: create, rename, delete (words remain), assign several; restart the
   app → unchanged.
4. Difficult: mark/unmark; list badge; difficult-only practice.
5. TTS: word and example on both platforms, with and without a German
   voice installed, with the Ring/Silent switch on silent (D45), offline,
   while music plays (ducked, then restored), tapping repeatedly.
6. Practice: complete a session, leave one midway (answers so far are kept),
   check statistics; change the device date/time zone and confirm past days
   do not move.
7. Reminder: turn on (permission prompt appears now, not at app start);
   deny → message; allow → notification at the chosen time; change the
   time; turn off → no notification; reboot (Android) → still scheduled;
   check behaviour across a DST change if possible.
8. Export CSV and `.apkg` to Files/Drive; open the CSV in Excel/Numbers/
   Google Sheets (Persian readable); re-import the CSV into a new deck.
9. Import the `.apkg` into Anki desktop, AnkiDroid and AnkiMobile; import a
   deck exported from each of them into the app (with and without "support
   older Anki versions"); a package with images/audio (media ignored).

## Review, FSRS, photo selection, TTS and bulk delete (D42–D47)

| Test file | Covers |
| --- | --- |
| `test/features/review/domain/review_scheduler_test.dart` | FSRS ratings, learning steps, graduation, growing intervals, lapses, determinism per direction |
| `test/features/review/domain/review_queue_test.dart` | Due rules (learning look-ahead, end of local day), new-card limits and order, one direction per day for "both", limit, direction setting parsing |
| `test/features/review/data/drift_study_repository_test.dart` | Card + event in one transaction, persistence, repeated reviews, local-day boundaries (UTC+3:30), daily new-card limit, independent directions, deck filter, deleted words, live due count |
| `test/drift/app_database/migration_test.dart` | A v1 database with old words and an old card row is reviewed with FSRS after migration; nothing lost |
| `test/features/review/presentation/practice_controller_test.dart` | Default direction, scheduled vs free, reveal required, double taps, re-queued learning steps, both directions over two days, difficult-only stays unscheduled, direction persisted |
| `test/features/speech/flutter_tts_speech_service_test.dart` | iOS playback session (once, before speaking, not on Android, retried after failure), rapid taps, restart, stop, refused language |
| `test/features/vocabulary/data/bulk_delete_test.dart` | Only selected words deleted; meanings, tags, card state cascade; history kept; unknown ids; 1200 ids |
| `test/features/scan/domain/page_layout_test.dart` | Word boxes ↔ characters (umlauts, ß, punctuation, hyphenation), hit tests with slop, misaligned boxes disable the photo view, image ↔ screen mapping incl. zoom/pan |
| `test/features/scan/presentation/scan_visual_selection_test.dart` | Photo kept only while scanning, three words from different paragraphs saved and nothing else, deselect/split/remove, disjoint selections, area crop → correction → item |
| `test/widgets/review_flow_test.dart` | Deck hides meanings (text and semantics), Start review shows one prompt, reveal, FSRS row written, direction from Settings survives restart, due count, nothing due → free practice, long-press selection, select all/clear, cancel/confirm delete, back leaves selection |
| `test/widgets/scan_visual_flow_test.dart` | Taps at real screen positions, pinch zoom keeps boxes aligned, hold-and-drag vs plain drag, area drawn on screen → correct photo region, view switching, 320 px at 2× text |

Automated tests cannot show: ML Kit's real word boxes and their alignment
with the decoded photo on a device, gesture feel, whether a German voice is
installed, how speech sounds, and the silent switch. See the manual checks
in the final report of this change and below.

Manual checks on a device (D42–D47):

1. Review German → Persian from Today: German shown, meaning hidden until
   "Show answer"; answer; the card returns after its learning step.
2. Settings → Review direction → Persian → German; restart; review shows the
   meaning first. Then "Both directions": each word once per day.
3. Answer some cards, close the app, reopen: due count reflects the answers;
   the next day graduated cards reappear only when due.
4. Open a deck: meanings hidden; eye icon shows them; long-press → select
   several → delete → confirm; cancel deletes nothing.
5. Pronunciation with the silent switch on, with music playing, offline.
6. Scan a page: tap three words in different paragraphs, zoom and tap
   more, touch-hold-drag an expression, draw an area around a misread word,
   correct it, continue, choose the deck, save; only those words are added.
