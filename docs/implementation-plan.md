# Implementation Plan and Roadmap

The project is delivered in **exactly five phases**. Each phase ends with a
report and waits for explicit approval before the next one starts. Each phase
is committed separately. Working rules for every phase are in
[claude-phase-instructions.md](claude-phase-instructions.md).

## Status labels

| Label | Meaning |
| --- | --- |
| **Complete** | Implemented, tested and committed. |
| **Implemented — awaiting commit** | Implemented and tested; not yet committed. |
| **Approved** | Scope approved for implementation in its phase. |
| **Planned (original specification)** | Part of the original product specification. Built when its phase is approved. |
| **Proposed — not approved** | Recorded for planning only. Must not be implemented until the product owner explicitly authorizes that specific feature. |

Platform status: iOS and Android builds are **unverified** (no Android SDK
and no full Xcode on the development machine). Verification so far is limited
to formatting, static analysis and host-side automated tests.

## Phase overview

| Phase | Theme | Status |
| --- | --- | --- |
| 1 | Foundation and local persistence | **Complete** (`73fa370`) |
| 2 | Vocabulary management and CSV import | **Complete** (`bbc9877`) |
| 3 | Photo/gallery input, German OCR, word and expression selection | **Complete** (`77287d7`) |
| 4 | AI enrichment with the user's own OpenRouter key (BYOK) | **Complete** (`eaa0278`); live OpenRouter and real-device/platform verification outstanding |
| 5 | Search, tags, export, Anki, TTS, reminders, practice and statistics (scope selected by the product owner) | **Complete** (`0402972`, follow-ups `aae5d5e`, `721ae7b`) |
| Build 3 | Release `1.0.0+3`: full backup/restore, About screen with release notes, AI sentence practice (product owner request, D54–D56) | **Complete** (see below) |

## Phase 1 — Foundation and local persistence — Complete (`73fa370`)

- Flutter project for iOS and Android (`com.aiwortbox.ai_wortbox`).
- Riverpod (state), GoRouter (navigation, five-tab shell), Material 3 theme
  with light/dark mode.
- Persian UI via `flutter gen-l10n` (Persian template + English).
- Centralized product/language configuration (`AppConfig`, `Language`).
- Drift database, schema v1: `decks`, `vocabulary_entries`,
  `vocabulary_meanings`, `flashcards`. Exported schema + verification test.
- Domain models: `Deck`, `DeckDraft`, `VocabularyEntry`, `VocabularyMeaning`,
  `EnrichmentMetadata`, `Flashcard`, `ReviewState`.
- Repository interfaces: `DeckRepository` (implemented),
  `VocabularyRepository` (implemented in Phase 2).
- Deck creation and listing, deck detail view.
- Unit, database, schema and widget tests.

## Phase 2 — Vocabulary management and CSV import — Complete (`bbc9877`)

- `DriftVocabularyRepository` (create/update/merge/delete/import, reactive
  queries with meanings). No schema change (still v1).
- `VocabularyDraft` (cleaning + validation), duplicate detection
  (`checkDuplicate`), deterministic import planning (`planImport`,
  `DuplicateStrategy`), non-destructive `mergeDrafts`.
- Screens: deck detail with searchable word list, entry detail, entry form
  (create/edit, duplicate dialog, "save & add next"), CSV import flow, Add tab
  actions for CSV and manual entry.
- CSV pipeline: own RFC 4180 parser with encoding/delimiter handling
  (`CsvParser`), header recognition and mapping (`HeaderRecognizer`,
  `ColumnMapping`), row analysis (`analyzeCsvImport`), `file_picker` adapter.
- Dependency added: `file_picker` 13.1.0. No CSV package (see D11).
- 11 CSV fixtures in `test/fixtures/csv/`, 86 new tests.

## Phase 3 — Photo/gallery input and German OCR — Complete (`77287d7`)

Scope:

- Camera capture and gallery selection of a book page.
- On-device German OCR. Google ML Kit text recognition (Latin script) is the
  candidate; German support must be verified on both platforms before relying
  on it.
- Interactive display of recognized text; selection of single words,
  contiguous multi-word expressions, multiple selection, deselection, reset.
- Context preservation: the surrounding sentence is stored in
  `vocabulary_entries.source_context` (column exists in schema v1).
- Correction screen: review and edit selected items and OCR errors before
  saving; explicit note that OCR can misrecognize words.
- Optional, conservative base-form (lemma) hints, always editable, never
  replacing the original spelling.
- Typed-text fallback when OCR fails or returns nothing.
- Saving only confirmed items to the selected deck (`source_type = image`);
  never saving every recognized word; full images are not uploaded anywhere.

Expected schema impact: none (uses existing v1 columns). Any change must
follow the migration policy below.

Likely dependencies (to be verified before adding): `google_mlkit_text_recognition`,
`image_picker`.

Related proposed (not approved) item: extended source metadata such as book
title and page (P5 below).

## Phase 4 — AI enrichment with the user's own key — Complete (`eaa0278`)

Architecture (product owner decision, D27/D28): **bring your own key
(BYOK)**. Each user enters their own OpenRouter API key; it is stored only in
OS-backed secure storage (iOS Keychain, Android Keystore-protected storage)
on the device. The Flutter app calls the OpenRouter API directly over HTTPS.
There is currently **no backend or proxy**. A backend that holds a shared
key is a possible future alternative behind the same provider-neutral
interface; it is not part of the current implementation.

Implemented:

- Provider-neutral `VocabularyEnrichmentService`; `OpenRouterEnrichmentService`
  as the current implementation; mocked HTTP and an in-memory key store in
  all automated tests.
- AI settings: explanation, hidden key entry, test, replace, remove, curated
  model choice; no request is sent without a saved key, and only on an
  explicit user action.
- Contextual Persian meanings (using the stored sentence context), German
  example sentences with Persian translations, grammar assistance, an
  optional base-form (lemma) field suggestion, ambiguity indicator.
- Schema-validated structured output, bounded batching, automatic retries
  only for requests rejected before generation (ambiguous failures such as
  timeouts are retried by the user, D32), cancellation, clear failure
  states, review before save, additions only (existing meanings and review
  state are never changed), protection of user-edited content.
- No API key in the app bundle, in committed configuration or in logs.

Not implemented from the original specification: response caching, and a
persisted `pending` status (failed or cancelled requests write nothing; see
D30).

Committed as `eaa0278`. Still outstanding: a live OpenRouter call with a
real key, and iOS/Android builds and real-device checks (secure storage,
backup exclusion, network, timeout behaviour). Until these run, Phase 4 is
verified only by host-side automated tests with mocked HTTP. See
`docs/testing.md`.

Proposed extensions in this phase (not approved): improved lemma and
inflected-form duplicate handling (P4), rich editable grammar data (P11),
user-added images and image suggestions (P13). See the register below.

## Phase 5 — Selected features — Implemented, awaiting commit

The product owner selected the Phase 5 scope explicitly: proposals P1, P2,
P3 (CSV export only), P6, P7, P8, P9, P10 and Anki import/export. They are
implemented as described below and in `docs/architecture.md` (decisions
D33–D40). Schema **v2** (one additive migration with tests from real v1
data).

| Feature | What is implemented |
| --- | --- |
| A — Search and filters (P1) | Search across all decks or within a deck, on the German word, base form and Persian meanings, in the database (`search_key`, `instr()`); filters for tag and difficult words; clear and no-result states. |
| B — Tags (P2) | Create, rename, delete (assignments removed, words kept), several tags per word, case/space-insensitive uniqueness, tag filter; CSV and Anki imports create and assign tags. |
| C — CSV export (P3, export part) | Per deck, UTF-8 with BOM, importer-compatible headers, tags included; saved with the system save dialog. **Not a backup** (see README). |
| D — German TTS (P6) | System text-to-speech (`de-DE`) for the word and example sentence; missing voices and engine errors are reported. |
| E — Study reminder (P7) | One daily local notification at a chosen time; permission asked only when turned on; inexact on Android; settings stored locally; re-created at app start. |
| F — Statistics and streaks (P8) | Totals, recorded answers, sessions, study days, current and longest streak, last 14 days — only from recorded practice answers, with a documented local-day policy. |
| G — Difficult words (P9, manual part) | Manual mark per word, list badge, filters, difficult-only practice. No automatic detection. |
| H — Reverse practice (P10, as free practice) | Persian → German: meaning first, reveal, "remembered"/"not remembered" recorded as review events. Not scheduled: no FSRS state is read or written. Superseded for scheduled review by D42–D43 (FSRS, direction setting); free practice keeps this behaviour. |
| I — Anki | Import of `.apkg` (modern `collection.anki21b` and legacy `collection.anki21`/`.anki2`) through the import preview; export of `.apkg` (legacy schema 11) verified with the official Anki importer (see `docs/testing.md`). |

Added after the Phase 5 scope on the product owner's request (D42–D47):
FSRS-scheduled review with a daily due queue and lazily created cards
(fulfilling D16), the review-direction setting, answers hidden in decks,
word selection on the page photo, the iOS speech fix and bulk delete.

Still **not implemented**: automatic difficult-word detection; media in
Anki import/export. (Full backup/restore followed in Build 3.) iOS/Android builds and real-device
checks remain outstanding (no Android SDK or full Xcode on the development
machine).

## Build 3 — release 1.0.0+3 (product owner request)

Approved and implemented together (decisions D54–D56):

| Feature | What is implemented |
| --- | --- |
| A — Full backup and restore | Versioned, checksummed JSON file with all learning data incl. FSRS state and review history (not the API key or settings); complete validation before any write; preview; merge (adds only) or replace (explicit confirmation); safety copy first; one transaction. `docs/backup-format.md`. |
| B — Installed version and release notes | Settings → About AI WortBox: version and build from the installed app, release notes (Persian/English) per build from `assets/release_notes.json`; a test requires notes for the pubspec build. `docs/releases.md`. |
| C — AI sentence practice | Today → AI sentence practice: write (Persian → German) or understand (German → Persian), levels A2–B2, 3/5/8 words, deck/tag filter; one request per session and one per checked answer through the shared free-only OpenRouter policy; validated exercises and feedback; history in schema v3, never touching FSRS or review history. |

Schema **v3** (one additive table). One dependency: `package_info_plus`.
Live OpenRouter calls are still unverified (mocked HTTP only).

## Proposed feature register

Items are **Proposed — not approved** unless the status column says
otherwise. Nothing proposed may be implemented, and no dependency or schema
change may be made for it, until the product owner explicitly authorizes
that specific feature. The phase column is the intended placement.

| ID | Feature | Intended phase | Status |
| --- | --- | --- | --- |
| P1 | Search and filters (German/Persian, deck, learning status) | 5 | Implemented in Phase 5 (text, deck, tag, difficult; no learning-status filter — there is no scheduler) |
| P2 | Tags and categories | 5 | Implemented in Phase 5 (flat tags) |
| P3 | CSV export and full local backup/restore | 5 | CSV export implemented in Phase 5; backup/restore implemented in Build 3 (D54) |
| P4 | Lemma / inflected-form duplicate detection | 4 (local hints from 3) | Proposed — not approved |
| P5 | Extended preservation of book sentences and source | 3 (metadata part) | Proposed — not approved |
| P6 | German text-to-speech | 5 | Implemented in Phase 5 (system TTS) |
| P7 | User-configurable local daily reminders | 5 | Implemented in Phase 5 (one daily reminder) |
| P8 | Streaks and progress statistics (no excessive gamification) | 5 | Implemented in Phase 5 (from practice answers) |
| P9 | Difficult words and targeted review | 5 | Manual mark and difficult-only practice implemented in Phase 5; automatic detection not approved |
| P10 | Reverse-direction flashcards | 5 | Implemented: FSRS-scheduled per direction with a German → Persian / Persian → German / both setting (D42, D43) |
| P11 | Rich editable grammar data | 4 | Proposed — not approved |
| P12 | Full offline access (principle) | Cross-cutting | Principle (all Phase 5 features work offline) |
| P13 | Images: user-added, suggestions, AI-generated | 4 (user-added, suggestions); AI-generated unscheduled | Proposed — not approved |
| — | Anki interoperability beyond CSV | 5 (evaluation first) | Evaluated and implemented in Phase 5 (see below) |

### P1 — Search and filters

- **Current state:** Phase 2 already provides per-deck search over the German
  word and Persian meanings (in memory, normalized).
- **Proposal:** search across all decks; filters by deck and learning status
  (new, learning, due, mature, difficult).
- **Dependencies:** learning status needs Phase 5 review state; P9 for
  "difficult"; P2 if filtering by tag.
- **Data model:** no change for text search at current sizes. Large
  collections may need an index or SQLite FTS5 virtual table (schema change).
- **Open decisions:** in-memory vs. FTS5; whether Persian search ignores
  diacritics/ZWNJ (current normalization ignores diacritics, not ZWNJ);
  where the global search lives in the navigation.

### P2 — Tags and categories

- **Proposal:** user-defined tags such as travel, work, grammar, B1, textbook.
- **Dependencies:** P1 (filter by tag), P3 (export/backup), Anki mapping
  (Anki has note tags).
- **Data model:** new `tags` table (id, name, normalized name, created_at) and
  `entry_tags` join table (entry_id, tag_id, unique pair, cascades). Schema
  migration v→v+1.
- **Open decisions:** flat tags vs. hierarchical categories; predefined
  suggestions (CEFR levels) vs. purely user-defined; tags per entry only or
  also per deck; CSV import column for tags (separator).

### P3 — CSV export and full local backup/restore

- **CSV export:** entries of one or more decks with all content fields and
  meanings (same conventions as the importer, UTF-8 with BOM option for
  Excel). Exchange format only — does not contain review state.
- **Backup/restore:** see "Backup and restore requirements" below.
- **Dependencies:** P2 and P13 (backup must include tags and media
  references when those exist); Phase 5 review log; a share/save mechanism
  for files.
- **Data model:** none for the database; defines an external, versioned file
  format.
- **Open decisions:** listed in the requirements section.

### P4 — Lemma and inflected-form duplicate detection

- **Current state:** duplicates compare the normalized original text only;
  `das Haus` and `Haus`, or `ging` and `gehen`, are not detected (known
  Phase 2 limitation).
- **Proposal:** also compare normalized lemmas and strip leading German
  articles for nouns; detect inflected forms via the AI lemma (Phase 4) and
  conservative local rules (Phase 3 hints). Distinct meanings must still never
  be merged without an explicit user choice; a lemma match is reported as a
  "possible duplicate", not an automatic one.
- **Dependencies:** Phase 3 lemma hints, Phase 4 AI lemma output.
- **Data model:** likely a `lemma_normalized` column with an index on
  `(deck_id, lemma_normalized)` (schema migration with backfill), or compute
  on the fly for small decks.
- **Open decisions:** article handling (der/die/das, reflexive "sich");
  whether separable verbs (e.g. "fängt … an" ↔ "anfangen") are matched;
  UI wording for "possible duplicate".

### P5 — Preservation of original book sentences and context

- **Approved part (Phase 3):** the surrounding sentence is stored in
  `source_context` and shown on the entry.
- **Proposed extension:** source metadata (book title, author, page,
  capture date), list of all entries from one book/page, showing the original
  sentence during review, keeping several contexts for the same word.
- **Dependencies:** Phase 3; Phase 5 review UI for showing context.
- **Data model:** a `sources` table (id, title, author, created_at) and
  optional `source_id`/`page` on entries, or a separate
  `entry_contexts` table for multiple contexts. Schema migration required.
- **Open decisions:** one vs. multiple contexts per entry; whether page
  photos are ever kept (default: no — only text is stored).

### P6 — German text-to-speech

- **Proposal:** play the German word and example sentence using the
  platform's on-device TTS.
- **Dependencies:** a TTS plugin (to be evaluated); availability of a German
  voice on the device (may require a download, may be unavailable offline).
- **Data model:** none (optional speech-rate setting).
- **Open decisions:** on-device only vs. cloud TTS (cloud would send text to
  a provider and needs backend/keys — default: on-device only); behaviour
  when no German voice is installed.

### P7 — User-configurable local daily reminders

- **Proposal:** one or more local notifications per day at user-chosen times,
  optionally only when cards are due. No server push.
- **Dependencies:** Phase 5 due counts; a local notifications plugin;
  notification permission (iOS, Android 13+), exact-alarm policy on Android,
  time zone handling.
- **Data model:** a settings store (key-value table or platform preferences);
  no vocabulary schema change.
- **Open decisions:** settings storage mechanism; reminder content (counts
  require scheduling ahead of time); default off.

### P8 — Streaks and progress statistics

- **Proposal:** days studied, current/longest streak, reviews per day,
  retention estimate, cards by state; calm presentation, no leaderboards,
  badges or pressure mechanics.
- **Dependencies:** Phase 5 review log (schema v2, already planned).
- **Data model:** derived from the review log; no extra tables expected.
- **Open decisions:** day boundary (local midnight vs. configurable rollover
  hour); whether a streak survives a missed day ("freeze"); wording that
  avoids implying permanent learning.

### P9 — Difficult words and targeted review

- **Proposal:** automatic detection from lapses / recent failures and an
  optional manual "difficult" mark; a separate practice session for these
  items.
- **Dependencies:** Phase 5 scheduler and review log.
- **Data model:** automatic detection needs none; a manual mark needs a
  column (e.g. `flashcards.marked_difficult` or on the entry) → migration.
- **Open decisions:** whether targeted practice affects FSRS scheduling
  (recommended: no — practice outside the scheduler, or documented
  explicitly); thresholds for "difficult".

### P10 — Reverse-direction flashcards

- **Note:** the original specification already mentions optional reverse
  cards in Phase 5; it is listed here because it was proposed again and its
  approval status must be confirmed before implementation.
- **Proposal:** Persian → German cards with independent FSRS state.
- **Dependencies:** Phase 5 scheduler.
- **Data model:** already supported (`flashcards.direction`, unique per
  entry and direction). Enabling per deck needs a deck setting column →
  migration.
- **Open decisions:** per deck vs. per entry; whether forward and reverse
  cards of the same entry are kept apart in one session ("sibling burying").

### P11 — Rich editable grammar data

- **Proposal:** structured, editable fields — noun article and plural; verb
  infinitive, key conjugations (present 3rd person, Präteritum, Perfekt with
  auxiliary); separable prefix; preposition + case; adjective comparison.
- **Dependencies:** Phase 4 AI output (filled by AI, edited by the user);
  P4 (lemma).
- **Data model:** currently `grammar_info` free text and `part_of_speech`.
  Options: a typed JSON column or a `grammar_details` table. Migration must
  keep the existing free text.
- **Open decisions:** structure (JSON vs. columns); how much conjugation to
  store; validation of user edits; display in review.

### P12 — Full offline access

- **Principle (original specification):** saved words, decks, search and
  review work without a network; only AI features (and optional cloud
  services, if ever approved) need connectivity.
- **Current state:** Phases 1–3 are fully offline. Phase 5 review must be
  offline. Phase 4 fails AI requests clearly without changing saved data
  (no automatic queue).
- **Data model:** none.
- **Open decisions:** whether pending AI requests are queued automatically
  when back online (requires user consent and cost limits).

### P13 — Images

Three separate capabilities, each requiring its own approval:

1. **User-selected images** (camera/gallery) attached to an entry. No
   network.
2. **Suggestions of existing images** from an image search/library service.
   Requires a provider evaluation (licence, attribution, content safety,
   privacy) and probably the backend for keys.
3. **AI-generated images.** Requires a separate provider evaluation. It must
   not be assumed that OpenRouter offers image generation; the design is
   provider-neutral (`ImageSuggestionService`, `ImageGenerationService`
   interfaces behind the backend).

- **Dependencies:** media storage, backup (P3) must include media files,
  key handling for any external provider (Phase 4 uses the user's own key;
  there is no backend).
- **Data model:** a `media` table (id, entry_id, kind, relative file path,
  MIME type, origin = user/suggested/generated, attribution/licence,
  created_at) with cascade on entry delete; files in the app's documents
  directory. Schema migration required.
- **Open decisions:** size/compression limits; one or several images per
  entry; showing images during review; cost limits for generation.

## Anki interoperability

Evaluated and implemented in Phase 5 (product owner selection), D39–D40.

- **Import (`.apkg`, also `.colpkg`):** notes of every note type are read as
  plain text (HTML to text, `[sound:…]` and images dropped, cloze markers
  reduced to their text) with their tags, and go through the normal import
  preview (column mapping, duplicate strategy, one transaction). Supported
  collection files: `collection.anki21b` (zstd-compressed SQLite, schema 18,
  the default since Anki 2.1.50), `collection.anki21` and `collection.anki2`
  (schema 11). The placeholder `collection.anki2` that new packages contain
  ("please update Anki") is rejected, never imported. Tested with packages
  written by the official Anki library 26.09.3 (fixtures in
  `test/fixtures/anki/`).
- **Export (`.apkg`):** `collection.anki2` (schema 11) with the note type
  "AI WortBox (German → Persian)" (fields German, Meaning, Lemma, Part of
  speech, Grammar, Example, Example translation, Notes, Context), one
  "German → Persian" card per note, tags, stable note GUIDs. Verified by
  importing it with the official Anki importer (26.09.3): all notes, fields
  and tags matched, and a second import was recognized as duplicates.
- **Not supported:** media (images, audio) in either direction; Anki
  scheduling and review history (exported cards are new); deck hierarchy
  (the user picks one target deck); exporting the reverse card template.
  Not tested in the Anki desktop GUI or AnkiDroid apps themselves — only with
  the official Anki library that those apps' import is built on (desktop)
  and the documented legacy format (AnkiDroid).

## Backup and restore requirements (for P3, not approved)

- **Versioned format:** a single archive (e.g. ZIP) with a manifest
  (backup format version, app version, database schema version, creation
  time, item counts, checksums) plus data and media files.
- **Contents:** decks and settings; vocabulary entries with all fields;
  all meanings in order; tags (when they exist); media references and media
  files (when they exist); flashcards with full scheduling state; review
  history.
- **Validation before restore:** supported format version, checksums,
  required fields, referential integrity (meanings → entries → decks,
  cards → entries), enum values, and migration of older schema versions.
  Invalid backups are rejected with a clear message and no changes.
- **Preview and confirmation:** show what will be restored (decks, entry and
  card counts, date, app version) and what will happen to current data, and
  require explicit confirmation.
- **Transactional restore:** all-or-nothing; automatic local safety backup of
  the current data before replacing it.
- **Location:** saved to a user-chosen local location or shared by the user
  through the system share sheet. **No upload to any cloud service by
  default.**
- **Open decisions:** data encoding (JSON vs. a copy of the SQLite file),
  replace-all vs. merge restore, optional password encryption, automatic
  periodic local backups.

## Schema change and migration policy

The current schema is **v3** (Build 3, D55: `sentence_practice_events`);
v2 came with Phase 5 (D33); Phases 2–4 made no schema changes.
Before any schema change:

1. Confirm the change is needed for an approved feature (no speculative
   columns or tables).
2. Document the change, its migration steps and data backfill in
   `docs/architecture.md` and a decision record.
3. Bump `schemaVersion`, run `dart run drift_dev make-migrations`, implement
   `stepByStep` upgrades, and add migration tests that start from real v1
   data.
4. Keep backup compatibility: a new table or column must be added to
   `BackupCodec` (and, if old files cannot be read, a new backup format
   version, D54).

Schema v2 (Phase 5) added `tags`, `entry_tags`, `review_events`,
`app_settings` and the entry columns `marked_difficult_at` and `search_key`.
FSRS (D42) needed no further migration. Proposed features P4, P5, P11 and
P13 would each require further migrations if approved.
