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

Feature providers (e.g. `deckSummariesProvider`) expose Drift `watch` streams,
so the UI updates automatically after writes. Tests override the root
providers with an in-memory database and deterministic clock/ids.

## Navigation

GoRouter with a `StatefulShellRoute.indexedStack` and five branches:
`/today`, `/words` (+ `/words/decks/:deckId`), `/add`, `/statistics`,
`/settings`. Each tab keeps its own navigation stack.

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

## Languages and localization

- `AppConfig` centralizes the product name, tagline and default language pair
  (German `de` → Persian `fa`).
- `Language` stores only an ISO code in the database; unknown codes are
  preserved (`Language.unknown`) so new languages need no schema change.
- UI strings come from `lib/l10n/app_fa.arb` (template) and `app_en.arb`. The
  app currently runs with the Persian locale (RTL).
- `AutoDirectionText` sets text direction from content, so German strings
  render correctly inside the RTL UI.

## Error handling

- Expected failures are `AppException` subtypes (`DeckValidationException`,
  `NotFoundException`, `StorageException`).
- Repositories validate input and wrap unexpected database errors in
  `StorageException`; the UI maps them to localized messages and never shows
  technical details.
- `main.dart` installs `FlutterError.onError` / `PlatformDispatcher.onError`
  handlers that log locally only.

## Security (planned for Phase 4)

The app never contains OpenRouter credentials. A minimal backend holds the key
and exposes `POST /api/v1/vocabulary/enrich`; the app sends only the selected
words and their sentence context.
