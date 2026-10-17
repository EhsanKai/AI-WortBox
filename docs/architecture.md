# Architecture

AI WortBox is a local-first Flutter app. All user data lives in an on-device
SQLite database; only AI enrichment (Phase 4) needs the network.

## Layers and folders

```
lib/
  main.dart                 Entry point, global error handlers
  app/                      App widget, router, shell, theme, root providers
  core/                     Cross-cutting: config, language, errors, clock,
                            id generation, text normalization, shared widgets
  data/database/            Drift tables and AppDatabase (schema + migrations)
  features/<feature>/
    domain/                 Entities, value objects, repository interfaces
    data/                   Repository implementations (Drift)
    presentation/           Screens, widgets, Riverpod providers
  l10n/                     ARB files + generated AppLocalizations
```

Dependencies point inwards: presentation → domain ← data. Domain code does not
import Drift or widgets. Scheduling (Phase 5), OCR (Phase 3), CSV parsing
(Phase 2) and enrichment (Phase 4) will live in `domain`/`data` and stay
independent of widgets.

## State management and dependency injection

Riverpod providers in `lib/app/providers.dart` wire the object graph:

- `appDatabaseProvider` — single `AppDatabase` (closed on dispose)
- `clockProvider` — `Clock` (`SystemClock`; `FixedClock` in tests)
- `idGeneratorProvider` — UUID v4 ids (`SequentialIdGenerator` in tests)
- `deckRepositoryProvider` — `DriftDeckRepository`
- `vocabularyRepositoryProvider` — `DriftVocabularyRepository`
- `csvFileSourceProvider` — `FilePickerCsvFileSource` (fake in tests)

Feature providers (e.g. `deckSummariesProvider`) expose Drift `watch` streams,
so the UI updates automatically after writes. Tests override the root
providers with an in-memory database and deterministic clock/ids.

## Navigation

GoRouter with a `StatefulShellRoute.indexedStack` and five branches. Each tab
keeps its own navigation stack.

| Path | Screen |
| --- | --- |
| `/today` | Dashboard |
| `/words` | Deck list |
| `/words/decks/:deckId` | Deck word list (search, add, import) |
| `/words/decks/:deckId/import` | CSV import into this deck |
| `/words/decks/:deckId/entries/new` | New word |
| `/words/decks/:deckId/entries/:entryId` | Word details |
| `/words/decks/:deckId/entries/:entryId/edit` | Edit word |
| `/add`, `/add/manual?deckId=`, `/add/csv?deckId=` | Add tab and its flows |
| `/add/scan?deckId=`, `/words/decks/:deckId/scan` | Page scan flow (Phase 3) |
| `/statistics`, `/settings` | Statistics, settings |

## Database

Drift, schema version **1**. DateTimes are stored as ISO-8601 text and always
written in UTC, so text comparisons on due dates are correct. Enum columns
store the enum value's `name`. Foreign keys are enabled in `beforeOpen`.

| Table | Purpose | Key constraints |
| --- | --- | --- |
| `decks` | Name, language pair, daily new-card limit | PK `id`; `daily_new_card_limit` 0–1000 |
| `vocabulary_entries` | Original text, normalized key, lemma, POS, examples, grammar, notes, source context, source type, enrichment status/metadata (JSON), `user_edited_at` | FK → decks (cascade); index `(deck_id, normalized)` (non-unique) |
| `vocabulary_meanings` | Ordered meanings per entry | FK → entries (cascade); unique `(entry_id, position)` |
| `flashcards` | Direction + FSRS state: state, step, stability, difficulty, due, last review, review/lapse counts, scheduler version | FK → entries (cascade); unique `(entry_id, direction)`; index `due` |

Vocabulary content and review state are in separate tables: editing an entry
never writes to `flashcards`, so progress is never reset by a definition edit
(covered by a test).

### Migrations

1. Change tables in `lib/data/database/tables.dart` and bump `schemaVersion`.
2. `dart run build_runner build`
3. `dart run drift_dev make-migrations` — exports
   `drift_schemas/app_database/drift_schema_vN.json`, generates
   `app_database.steps.dart` and migration tests under `test/drift/`.
4. Implement `onUpgrade` with `stepByStep(...)`, run tests.

The exported v1 schema is checked by `test/drift/app_database/schema_test.dart`.

## Vocabulary

- `VocabularyDraft` is the editable content of an entry. `cleaned()` trims
  and collapses whitespace, drops blank and repeated meanings, and keeps the
  original spelling; `validate()` checks required word and length limits.
  Meanings are optional.
- `enrichmentStatus`: `ready` when an entry has at least one meaning (from
  the user, a CSV file or later AI), `missing` when it has none. Only
  `missing`/`failed` entries will be candidates for AI enrichment (Phase 4),
  so imported translations never trigger unnecessary requests.
- `userEditedAt` is set when the user creates or edits an entry in the form
  (and on an explicit "add meanings" merge). CSV imports do not set it.
  Phase 4 must not overwrite such content without confirmation.
- Repositories never write to `flashcards` when content changes. Deleting an
  entry deletes its cards (cascade); the UI warns about this.

### Duplicates

Duplicates are detected per deck by `normalized` (case-insensitive, edge
punctuation removed, umlauts composed). A duplicate is *redundant* when its
meanings are a subset of an existing entry's meanings (compared with
`TextNormalizer.meaningKey`, which also unifies Persian letter variants and
ignores diacritics). A word with *different* meanings is never merged
automatically:

- Manual entry: a dialog offers cancel / open existing (redundant) or cancel /
  add meanings to existing / save as a separate word (different meanings).
- CSV import: `planImport` applies the chosen `DuplicateStrategy` (`skip`,
  `mergeMeanings`, `keepSeparate`) in file order, treating earlier rows like
  existing entries. Redundant rows are always skipped. Merges only append
  meanings and fill empty fields.

## CSV import pipeline

```
bytes ─ CsvParser.decode ─ detectDelimiter / sep= ─ CsvParser.parse ─▶ CsvTable
CsvTable ─ HeaderRecognizer.suggest ─▶ ColumnMapping (user-adjustable)
(CsvTable, ColumnMapping, existing entries, strategy) ─ analyzeCsvImport ─▶ preview
preview.candidates ─ VocabularyRepository.importEntries (one transaction)
```

All steps except the file picker and the final write are pure Dart and unit
tested. `importEntries` re-plans inside the transaction against the current
database state, so the result does not depend on a stale preview. Any failure
rolls back the whole import. Files above 256 KB are parsed on a background
isolate.

## Page scanning (Phase 3)

Photo or gallery image → on-device OCR → word/expression selection →
review and correction → transactional save. No schema change (uses the v1
columns `source_context`, `lemma` and `source_type = image`).

```
ScanImageSource (image_picker)  ─▶ PickedImage ─ validatePickedImage
TextRecognitionEngine (ML Kit)  ─▶ ScanText (normalized text + line boxes)
ScanDocument (TextTokenizer)    ─▶ word tokens with character offsets
WordSelection (offset ranges)   ─▶ ScanReviewItem (text, sentence, hint)
ScanReviewItem.toDraft          ─▶ VocabularyRepository.importEntries
```

- **Interfaces** (`features/scan/data`): `ScanImageSource` (pick from camera
  or gallery, Android lost-data recovery, deleting the temporary photo) and
  `TextRecognitionEngine` (recognize, availability, dispose). Production
  implementations: `ImagePickerScanImageSource`,
  `MlKitTextRecognitionEngine`; tests use fakes. Both are provided through
  Riverpod (`scanImageSourceProvider`, `textRecognitionEngineProvider`).
- **Text** (`features/scan/domain`): `ScanText` keeps the normalized text the
  user sees, the raw recognizer output, its origin (OCR, typed, edited) and
  per-line bounding boxes from OCR. `OcrTextNormalizer` only applies
  encoding-level fixes (line endings, decomposed umlauts, ligatures, soft
  hyphens, invisible characters, extra spaces); words and punctuation are
  never changed.
- **Tokens and selection**: `TextTokenizer` produces word tokens (letters
  incl. umlauts/ß, inner hyphens/apostrophes) with exact offsets. Words
  hyphenated across a line break are shown joined and marked with a dotted
  underline ("Ver-⏎ständnis" → "Verständnis"; "Nord-⏎Süd" keeps the hyphen;
  "Ein-⏎und" is not joined). `WordSelection` stores character ranges, so
  selections do not depend on screen layout; after a text correction they
  are remapped (unchanged parts kept, edited parts dropped and reported).
- **Expressions**: in "expression" mode the user taps the first and last
  word; the range must stay within one paragraph and at most 10 words.
- **Context**: `SentenceContext` finds the sentence around a selection
  (handles German abbreviations such as "z. B.", "Dr.", ordinals like
  "3. Mai", quotes and paragraph breaks), joins lines and hyphenation, and
  limits it to 400 characters around the selection.
- **Base-form hints**: `LemmaHints` is a small, offline, curated list of
  unambiguous irregular verb forms ("ging" → gehen). Hints are shown with a
  "please check" note and only fill the optional base-form field when the
  user taps "Use". The selected form is always saved as `original`.
- **Saving**: review items become `VocabularyDraft`s
  (`sourceType = image`, `sourceContext` = sentence) and are saved with
  `importEntries`, i.e. one transaction, the same duplicate rules and the
  same three `DuplicateStrategy` options as CSV import (default: skip).
  Items already in the deck are marked and not saved again.
- **Privacy**: the picked photo is a temporary copy that is deleted right
  after recognition (also on errors). Images are never uploaded or stored.
- **State**: `ScanController` (Riverpod, one per screen instance) drives the
  steps capture → (typing) → select → review → done inside one route; the
  back button returns to the previous step.

## Languages and localization

- `AppConfig` centralizes the product name, tagline and default language pair
  (German `de` → Persian `fa`).
- `Language` stores only an ISO code in the database; unknown codes are
  preserved (`Language.unknown`) so new languages need no schema change.
- UI strings come from `lib/l10n/app_fa.arb` (template) and `app_en.arb`. The
  app currently runs with the Persian locale (RTL).
- `AutoDirectionText` sets text direction from content, so German strings
  render correctly inside the RTL UI. Input fields set their direction by
  language: German fields LTR, Persian fields RTL.

## Error handling

- Expected failures are `AppException` subtypes (`DeckValidationException`,
  `NotFoundException`, `StorageException`).
- Repositories validate input and wrap unexpected database errors in
  `StorageException`; the UI maps them to localized messages and never shows
  technical details.
- `main.dart` installs `FlutterError.onError` / `PlatformDispatcher.onError`
  handlers that log locally only.

## AI enrichment (Phase 4 — implemented, awaiting commit)

Bring your own key: each user's OpenRouter key in OS secure storage, direct
HTTPS calls from the app, no backend or proxy (D27, D28). A backend is a
possible future alternative behind `VocabularyEnrichmentService`; it is not
implemented.

```
EnrichmentScreen ── EnrichmentController ── VocabularyRepository.applyEnrichments
                         │                     (one transaction, additions only)
                         ├─ EnrichmentPlan (review rules)
                         └─ VocabularyEnrichmentService (interface)
                                └─ OpenRouterEnrichmentService
                                     ├─ AiSettingsStore (key + model, OS secure storage)
                                     └─ OpenRouterClient ──HTTPS──▶ openrouter.ai/api/v1
```

- **Domain** (`features/enrichment/domain`): `EnrichmentRequest` (word,
  sentence context, existing meanings — nothing else is sent),
  `EnrichmentProposal`, the strict JSON schema and `EnrichmentParser`
  (Persian meanings, German example + Persian translation as a pair,
  German lemma, length limits, control characters removed),
  `EnrichmentPlan` (what may be added or filled, defaults), the curated
  `AiModelCatalog`.
- **Data** (`features/enrichment/data`): `OpenRouterClient` maps the
  documented statuses (400/401/402/403/408/429/502/503, and 200 with an
  `error` body). It retries automatically only requests OpenRouter rejected
  before any model ran (429, 503, 402 with `Retry-After`), at most twice,
  with backoff or `Retry-After` (capped at 20 s). Client timeouts (45 s),
  network failures, 408/500/502 and 200-with-error fail at once and are
  retried only by the user (D32). Supports cancellation.
  `SecureAiSettingsStore` wraps `flutter_secure_storage`; a failed key or
  model write is shown in Settings → AI, and the screen then shows the key
  that is actually stored.
- **Presentation**: Settings → AI (explanation, link to openrouter.ai/keys,
  hidden key field, test, replace, remove, model, privacy and security
  notes); AI suggestions from a deck (entries without meanings) or from one
  entry; review with per-meaning and per-field checkboxes.
- **Offline**: nothing AI-related runs without a user action; without a
  connection requests fail with a network message and nothing changes. All
  other features are unaffected.

## Security

- No API key in the source, assets, build configuration or the app bundle.
  The user's key is stored only in OS secure storage (D28), sent only in the
  `Authorization` header to `openrouter.ai`, and never logged or put into
  exceptions.
- Only the selected word, its sentence context and its current meanings are
  sent, and only when the user asks.

## Planned extension points (proposed — not approved)

This section records how proposed features would fit the architecture. It is
planning only: none of it is implemented, and no schema, dependency or code
change may be made for it without explicit approval. Feature IDs refer to the
register in [implementation-plan.md](implementation-plan.md).

### Phase 3 boundaries (approved)

- OCR sits behind a provider-neutral `TextRecognitionEngine` interface in
  `features/scan/data`, so the ML Kit adapter can be replaced and tests use a
  fake. Selection logic (tokens with stable character offsets, contiguous
  expressions, sentence boundaries) is pure Dart in `features/scan/domain`.
- Confirmed items become `VocabularyDraft`s with `sourceType = image` and
  `sourceContext` set, and are saved through the existing
  `VocabularyRepository`, reusing duplicate detection. No schema change.

### Data model implications of proposals

| ID | Likely change | Migration notes |
| --- | --- | --- |
| P2 tags | `tags`, `entry_tags` tables | Additive; cascades on entry delete |
| P4 lemma duplicates | `lemma_normalized` column + index | Backfill from `lemma`/`original` |
| P5 sources | `sources` table and/or `entry_contexts` table | Move existing `source_context` into it, or keep column and add table |
| P9 manual difficult mark | one boolean column | Additive, default false |
| P10 reverse cards per deck | one deck setting column | Additive; card rows already support `direction` |
| P11 structured grammar | JSON column or `grammar_details` table | Keep existing `grammar_info` text |
| P13 media | `media` table + files in documents dir | Backup must include files |
| P7 reminders, P6 TTS | settings storage | Prefer a key-value settings table or platform preferences; decide once |
| P1, P8, P12 | none expected | P1 may need FTS5 for large collections |

Planned (original specification): schema v2 adds a review log table in
Phase 5.

### Backup format boundary (P3)

A `BackupService` in the data layer would export and import a versioned
archive. Restore would run in four steps — read → validate → preview →
transactional apply — with an automatic safety backup of the current data.
It would never send data to a network service. The backup format version is
independent of the database schema version; the manifest records both.

### Images boundary (P13)

Three independent interfaces, each enabled separately:

- `UserImageSource` — camera/gallery, local only.
- `ImageSuggestionService` — searches existing images through the backend;
  results carry licence and attribution.
- `ImageGenerationService` — AI image generation through the backend, with a
  provider chosen after a separate evaluation. OpenRouter is not assumed to
  support image generation.

Images are stored as local files referenced from a `media` table, never
inside SQLite rows.

### Anki boundary

CSV/text exchange uses the existing CSV pipeline (import) and a future
exporter. `.apkg` support would be a separate adapter, added only after the
evaluation described in the roadmap; it must not shape the core data model
before that evaluation.
