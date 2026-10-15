# Implementation Plan

The project is delivered in five phases. Each phase ends with a report and
waits for explicit approval before the next one starts.

## Phase 1 — Foundation and local persistence ✅ (awaiting approval)

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

## Phase 2 — Vocabulary management and CSV import

- `DriftVocabularyRepository`; create/edit/view/delete entries with multiple
  meanings, examples and notes; field validation.
- Duplicate detection via `normalized` (never merges distinct meanings).
- CSV import: file picker, UTF-8/BOM, delimiter detection, header recognition
  (`word`, `term`, `german`, `meaning`, `translation`, `persian`, `example`),
  column mapping, preview, row-level errors, duplicate options, transactional
  commit. Entries with meanings are marked so they skip AI enrichment.
- Likely dependencies: `file_picker`, `csv`.

## Phase 3 — Book scanning and word selection

- Camera/gallery capture, on-device OCR (Google ML Kit text recognition, Latin
  script; German support to be verified per platform).
- Token model with stable offsets for selecting words and contiguous
  expressions; selection review and correction; sentence context capture;
  optional conservative lemma hints; editable text fallback.
- Likely dependencies: `google_mlkit_text_recognition`, `image_picker`.

## Phase 4 — OpenRouter AI enrichment

- `VocabularyEnrichmentService` interface; mock implementation for
  development/tests; HTTP implementation against a minimal backend
  (`POST /api/v1/vocabulary/enrich`) that holds the OpenRouter key.
- Schema-validated structured output, batching, bounded retries, caching,
  cancellation, and protection of user-edited content (`user_edited_at`).

## Phase 5 — FSRS review and release readiness

- Scheduler adapter around the `fsrs` Dart package (v2.x, verified in Phase 1
  to model learning/review/relearning, stability, difficulty, step, due).
- Daily queue with new-card limits, review session UI with Persian labels,
  optional reverse cards, duplicate-submission protection, review log table
  (schema v2 migration), statistics, final QA and full README.
