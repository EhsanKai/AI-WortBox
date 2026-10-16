# Decisions

Short records of decisions and their reasons. Newest last.

## D1 — Flutter, Riverpod 3, GoRouter, Drift (2026-10-15)

Required by the specification. Versions: Flutter 3.47.7 / Dart 3.13.5,
flutter_riverpod 3.4, go_router 18.1, drift 2.35 with `drift_flutter` 0.3
(opens the database in a background isolate on device). No Riverpod code
generation, to keep the build simple.

## D2 — Full v1 schema up front (2026-10-15)

All four core tables are created in schema v1, even though entries and cards
are used only from Phase 2/5. This fixes the data model early, as the
specification requires, and avoids migrations for the core shape. Additive
changes (e.g. a review log table in Phase 5) will be schema migrations.

## D3 — Meanings in a separate table (2026-10-15)

`vocabulary_meanings` with a `position` column supports any number of ordered
meanings, optional explanations and per-meaning edits, without JSON
parsing in queries.

## D4 — Review state separated from vocabulary content (2026-10-15)

`flashcards` holds all scheduler state; entries hold content. One card per
`(entry, direction)` so reverse cards have independent scheduling. Fields
mirror the `fsrs` Dart package 2.0.1 card (state, step, stability,
difficulty, due, last review) plus review/lapse counts and a
`scheduler_version`. The final FSRS library choice is confirmed in Phase 5.
`CardState.newCard` marks never-reviewed cards (the `fsrs` package has no
"new" state).

## D5 — UTC ISO-8601 text timestamps (2026-10-15)

`store_date_time_values_as_text: true`; all writes use `Clock.nowUtc()`.
This keeps millisecond precision and makes due-date comparisons correct.

## D6 — Case-insensitive unique deck names checked in Dart (2026-10-15)

SQLite `lower()`/`NOCASE` only fold ASCII. Duplicate names are detected with
`TextNormalizer.nameKey` inside the insert transaction, so "Übung" and
"übung" are treated as the same deck name.

## D7 — Normalization is for comparison only (2026-10-15)

`TextNormalizer` composes decomposed German umlauts, unifies Arabic/Persian
look-alike letters (ي/ى→ی, ك→ک), collapses whitespace, and lower-cases.
Originals are always stored unchanged. Full Unicode NFC is not available in
the Dart SDK; only the cases relevant for German and Persian are handled.

## D8 — Persian-only UI locale for the MVP (2026-10-15)

The target users are Persian speakers, so the app is forced to `fa` (RTL).
An English ARB exists to keep localization ready; a language switch is out of
MVP scope. Dates use the Gregorian calendar with Persian month names and
digits (intl has no Jalali calendar).

## D9 — Daily new-card limit 0–1000, default 20 (2026-10-15)

`0` pauses new cards (as in Anki). Enforced in the domain and by a database
CHECK constraint.

## D10 — In-memory test database and UUID ids (2026-10-15)

Records use app-generated UUID v4 string keys (stable, merge-friendly for any
future sync). Tests use `NativeDatabase.memory()` and deterministic ids.

## D11 — Own CSV parser instead of `package:csv` (2026-10-15)

`csv` 8.0.0 is maintained, but it tolerates malformed input silently, does not
report line numbers or unterminated quotes, and converts values to numbers by
default. Row-level error reporting needs all three. A ~200-line RFC 4180
parser (`CsvParser`) handles quotes, escapes, multi-line cells, CR/LF/CRLF,
BOM/UTF-16, delimiter detection and `sep=` hints, with tests for each.

## D12 — `file_picker` with `FileType.any` (2026-10-15)

`file_picker` 13.1.0 (160/160 pub points, Flutter ≥ 3.38). Extension filters
can hide CSV files on some Android document providers that report unusual
MIME types, so any file can be chosen; content is validated by the parser
(non-Unicode and binary files are rejected with a clear message).

## D13 — Meanings are optional; status reflects presence (2026-10-15)

Words collected without a translation (e.g. from scans in Phase 3) must be
storable. An entry without meanings is `missing`; with meanings it is `ready`.
Imported or typed translations therefore never trigger AI enrichment.

## D14 — Only Unicode encodings are accepted (2026-10-15)

Non-UTF input (e.g. Windows-1256 or Latin-1) is rejected instead of guessed,
because a wrong guess silently corrupts Persian text. The error message tells
the user to save the file as UTF-8.

## D15 — Meaning separators inside a cell (2026-10-15)

`;`, `؛`, `|` and line breaks split a cell into several meanings. Commas do
not, because `,` and `،` occur inside Persian and German phrases.

## D16 — Flashcards are created in Phase 5 (2026-10-15)

Phase 2 stores vocabulary only. Cards (and their FSRS state) will be created
for entries when the review feature is implemented, including for entries
saved before then.

## D17 — Exactly five phases; proposals need separate approval (2026-10-15)

Status: accepted (roadmap rule).

The roadmap keeps five phases. Additional features are recorded in a
proposed-feature register (P1–P13 in `implementation-plan.md`) with an
intended phase, dependencies, data-model implications and open decisions.
Proposed features are not implemented, and no schema or dependency change is
made for them, until the product owner explicitly approves each one.

## D18 — CSV exchange is separate from Anki `.apkg` compatibility (2026-10-15)

Status: accepted (principle). `.apkg` support itself: not approved.

CSV/text exchange (content only) is the supported interoperability path.
Complete `.apkg` compatibility is not promised. It would cover notes, note
types/templates, deck structure, tags, media and scheduling/review history.
It requires an evaluation against real Anki exports before any scope is
proposed.

## D19 — Backup/restore principles (2026-10-15)

Status: accepted (principle). Feature (P3): not approved.

If built, backups are versioned and validated. They include vocabulary,
ordered meanings, decks, tags, media references/files and full review state.
Restoring requires a preview and an explicit confirmation, runs in a single
transaction and makes a safety backup first. Backups are stored locally or
shared by the user. Nothing is uploaded to a cloud service by default.

## D20 — Images are three separate capabilities (2026-10-15)

Status: accepted (principle). Features (P13): not approved.

User-selected images, suggestions of existing images and AI-generated images
are designed and approved separately behind provider-neutral interfaces.
OpenRouter is not assumed to provide image generation; any image provider is
evaluated separately for cost, licensing, privacy and content safety.

## D21 — No speculative schema changes (2026-10-15)

Status: accepted.

Schema changes are made only for approved features, each documented with its
migration and backfill before implementation, and tested with migration tests
from real older data. The schema remains v1 after Phase 2.

## D22 — OCR with Google ML Kit, images with `image_picker` (2026-10-16)

Status: accepted (Phase 3).

- `google_mlkit_text_recognition` 0.17.1 (flutter-ml.dev, Android + iOS).
  Google lists German (`de`, Latin script) among the prioritized, regularly
  evaluated languages of ML Kit Text Recognition v2. The Latin model is
  bundled (Android: `com.google.mlkit:text-recognition:16.0.1`; iOS:
  `GoogleMLKit/TextRecognition`), so OCR works offline without a model
  download. Other scripts are not bundled.
- Requirements: Android minSdk 21 (Flutter default is higher); iOS 15.5 or
  newer, 64-bit only. The iOS deployment target was raised from 15.0 to 15.5
  in the Xcode project, and `ios/Podfile` (from Flutter's template) sets the
  platform, excludes armv7 and enforces the deployment target for pods.
- `image_picker` 1.2.4 (flutter.dev) for camera and gallery, with
  downscaling to 3000 px and JPEG quality 92, without full metadata.
  Info.plist contains camera and photo-library usage descriptions; Android
  needs no extra permissions (system camera/photo picker intents).
- The OCR engine and image source sit behind interfaces so they can be
  replaced (e.g. a different OCR engine) and faked in tests.
- Not verified: real builds and on-device behaviour (no Android SDK, no full
  Xcode). ML Kit is reported not to run on some iOS simulators; real-device
  testing is required.

## D23 — Select from a tokenized text view, not an image overlay (2026-10-16)

Status: accepted (Phase 3).

Selection happens on the recognized text, shown as tappable words in a
left-to-right view inside the Persian UI. This works the same for OCR,
typed and corrected text, keeps touch targets large, and stores selections
as character offsets. OCR line boxes are kept in `ScanText.lines` for a
possible future overlay, but are not used by the UI.

## D24 — Hyphenation is joined visibly, never silently (2026-10-16)

Status: accepted (Phase 3).

The normalizer never changes words. Words split by a hyphen at a line end
are joined only in the token display (dotted underline) and in the saved
item, which the user reviews and can edit before saving.

## D25 — Offline base-form hints from a curated list only (2026-10-16)

Status: accepted (Phase 3).

No AI and no general stemming in Phase 3. Only unambiguous irregular verb
forms produce a hint; ambiguous forms (e.g. "gestanden", "gefallen",
"gelassen") and regular inflection produce none. Better lemma handling is
part of the Phase 4 plan / proposal P4.

## D26 — Scanned items reuse the import path (2026-10-16)

Status: accepted (Phase 3).

Saving uses `VocabularyRepository.importEntries` with the user's
`DuplicateStrategy`, so scanned words follow exactly the CSV duplicate rules,
are saved in one transaction, and never overwrite existing meanings. Imports
do not set `userEditedAt`; meanings typed on the review screen are user
content either way (entries with meanings are `ready` and are not candidates
for AI enrichment).
