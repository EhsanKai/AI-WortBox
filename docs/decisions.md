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

## D27 — Bring your own OpenRouter key; no shared backend (2026-10-16)

Status: accepted (Phase 4, product owner decision). Supersedes the planned
"minimal backend that holds the OpenRouter key" (architecture/roadmap text
written before this decision).

- Every user uses their own OpenRouter account and key, so AI usage is
  billed to that account. There is no developer-owned key, no shared proxy
  and no fallback key.
- The app calls the documented OpenRouter API directly
  (`https://openrouter.ai/api/v1`): `POST /chat/completions`, `GET /key`
  (key check and reported usage), public `GET /models` (model check, sent
  without the key). Verified against the official documentation on
  2026-10-16; no live call has been made from this project.
- No request is sent without a saved key, and only on an explicit user
  action ("Get suggestions", "Test key").
- The integration sits behind `VocabularyEnrichmentService`; a backend-based
  implementation is a possible future alternative that could replace
  `OpenRouterEnrichmentService` without changing the review/save logic or
  the UI. It is not part of the current implementation.

## D28 — The key lives only in OS secure storage (2026-10-16)

Status: accepted (Phase 4).

- `flutter_secure_storage` 11.2.0 (steenbakker.dev, 160/160 pub points;
  Android minSdk 23, Flutter's default here is 24). iOS: Keychain with
  `unlocked_this_device` (not synced to iCloud Keychain, not restored to
  another device). Android: AES-GCM values with the key protected by the
  Android Keystore (plugin defaults).
- Android Auto Backup and device transfer exclude exactly the plugin's
  SharedPreferences files (`res/xml/backup_rules.xml`,
  `res/xml/data_extraction_rules.xml`); the vocabulary database is still
  backed up as before.
- Never in SQLite, ordinary preferences, logs or exceptions
  (`EnrichmentException` carries only a reason and HTTP status; OpenRouter
  error messages are not stored). The UI keeps only the last four
  characters; the full key is never shown after saving. The key field
  disables autocorrect, suggestions and IME learning.
- The non-secret model id is stored next to the key to avoid a second
  storage mechanism.
- Limitation, also shown in the app: secure storage reduces exposure but a
  compromised or instrumented device can still extract the key; users are
  advised to set a credit limit on the key. On iOS, Keychain items can
  survive app deletion; "Remove key" deletes it explicitly.

## D29 — Structured output and a curated model list (2026-10-16)

Status: accepted (Phase 4).

- Requests use `response_format: json_schema` (strict) and
  `provider.require_parameters: true`, so OpenRouter routes only to
  endpoints that support structured outputs. The response is still treated
  as untrusted and validated (`EnrichmentParser`).
- Curated models, all listed with `structured_outputs` and without an
  expiry date in the public model list on 2026-10-16:
  `anthropic/claude-haiku-5.5` (default), `google/gemini-3.5-flash-lite`,
  `openai/gpt-5-mini`, `openai/gpt-4o-mini`,
  `mistralai/mistral-small-3.2-24b-instruct`. "Test key" checks the selected
  model against the live list. No live model picker in Phase 4.
- Costs: only the `usage.cost` OpenRouter reports per response and the key
  usage from `GET /key` are shown. Nothing is estimated.

## D30 — Review before save; additions only; no migration (2026-10-16)

Status: accepted (Phase 4).

- Nothing is written until the user reviews the proposal. Existing meanings
  are never removed or changed; only new meanings can be added. Empty fields
  are preselected for filling; fields with content are offered only as
  explicit replacements (never preselected). For entries that already have
  meanings, nothing is preselected.
- Batches include only entries without meanings (`missing`/`failed`, at most
  50). Entries with meanings are enriched only on request from their own
  page.
- Saving uses `VocabularyRepository.applyEnrichments`: one transaction,
  optimistic check of each entry's `updatedAt` (any change since the
  proposal aborts the whole save), additions/fills only, `enrichmentStatus`
  `ready`, metadata (provider, model, time, ambiguity) in the existing
  `enrichment_metadata` column. `userEditedAt` and flashcards are never
  touched. Failed or cancelled requests write nothing (status is not set to
  `pending`/`failed` in the database).
- The v1 schema already had every needed column; no migration.

## D31 — `http` and `url_launcher` (2026-10-16)

Status: accepted (Phase 4).

- `http` 1.6.0 (dart.dev, 160/160): HTTPS client; `MockClient` makes every
  automated test network-free. Was already a transitive dependency.
- `url_launcher` 6.3.x (flutter.dev, Flutter Favorite): opens
  `https://openrouter.ai/keys` in the browser. Android 11+ needs the
  `<queries>` entry for https added to the manifest.
- The release Android manifest now declares `INTERNET` (Flutter adds it only
  to debug/profile builds).

## D32 — No automatic retry of possibly billed requests; visible storage errors (2026-10-17)

Status: accepted (Phase 4 hardening).

- Generation is billed per request. A client timeout, a dropped
  connection, HTTP 408/500/502, or a 200 response carrying an `error`
  object do not prove that nothing was generated, so repeating them
  automatically could bill the user twice. These fail at once; the item is
  marked failed and the user can choose "Retry failed items". The timeout
  message says the request may already have been processed and charged.
- Automatic retries (at most 2, backoff or capped `Retry-After`) remain only
  for statuses with which OpenRouter refuses a request before routing it to
  a model: 429 (rate limit), 503 (no provider meets the routing
  requirements) and 402 with `Retry-After` (temporary in-flight budget).
  This classification follows OpenRouter's documented error codes; whether
  OpenRouter bills any failed request has not been verified with a live
  account.
- The key check (`GET /key`) and model list are free and not retried.
- Secure-storage failures when saving, replacing or removing the key, or
  saving the model, are shown in Settings → AI. No success state is shown
  unless the write succeeded; after a failure the screen re-reads the stored
  key. Errors carry only the platform error code, never the key.

## D33 — Schema v2: additive migration for Phase 5 (2026-10-19)

Status: accepted (Phase 5).

- New tables `tags`, `entry_tags` (cascade on entry and tag delete),
  `review_events` (`entry_id` set to null when the word is deleted, so
  history and statistics do not change retroactively) and `app_settings`
  (non-secret key-value settings). New nullable/defaulted columns on
  `vocabulary_entries`: `marked_difficult_at`, `search_key`.
- `from1To2` only adds tables, columns and indexes, then computes
  `search_key` for existing entries from their stored word, base form and
  meanings. No existing value is changed; covered by a data-integrity
  migration test with real v1 rows (Persian meanings with Arabic letters
  and ZWNJ, enrichment metadata, flashcards).
- The `flashcards` table is unchanged and still unused (no scheduler).

## D34 — Search runs in the database on a stored search key (2026-10-19)

Status: accepted (Phase 5).

- `search_key` holds one comparison key per line: the German word and base
  form (`TextNormalizer.vocabularyKey`: case, umlaut composition, edge
  punctuation) and each meaning (`meaningKey`, plus ZWNJ removed). It is
  rewritten on every content write and never shown.
- Queries use `instr(search_key, key) > 0` (exact substring; typed `%` and
  `_` are not wildcards), combined with deck, tag and difficult filters, at
  most 300 results. No FTS table: simple, offline and fast enough for
  personal collections; revisit only with real performance data.
- Policy: ZWNJ is ignored (می‌روم = میروم); a space is not treated as ZWNJ.

## D35 — Practice is not spaced repetition (2026-10-19)

Status: accepted (Phase 5, product owner scope).

- Persian → German practice shows the meaning, reveals the German word on
  request and records the learner's own "remembered/not remembered" as a
  review event (`direction = reverse`). It never reads or writes
  `flashcards`, never changes vocabulary, and does not adapt anything.
- Only these explicit answers count as reviews. Opening the app, a word or a
  practice screen records nothing.
- Difficult words are a manual mark only (no automatic detection; see P9).

## D36 — Local-day and streak policy (2026-10-19)

Status: accepted (Phase 5).

- Each event stores its UTC time and the device's local calendar day at
  recording time (`YYYY-MM-DD`). Statistics group by that stored day, so a
  later time-zone change does not move past reviews.
- A study day has ≥ 1 recorded answer. The current streak counts
  consecutive study days ending today, or ending yesterday while today has
  no answer yet; otherwise 0. The longest streak is the longest such run.
  No streak "freezes". Wording avoids implying permanent learning.

## D37 — Study reminder: local notifications only (2026-10-19)

Status: accepted (Phase 5).

- `flutter_local_notifications` 22.3.2 (dexterx.dev), `timezone` 0.11.2
  (labs.dart.dev) and `flutter_timezone` 5.1.1 (device IANA zone). One
  notification id, repeating daily at local wall-clock time
  (`DateTimeComponents.time`), so DST does not shift it and rescheduling
  replaces instead of duplicating.
- Permission is requested only when the user turns the reminder on, never
  at startup. Android: `POST_NOTIFICATIONS` (runtime, 13+),
  `RECEIVE_BOOT_COMPLETED` and the plugin's receivers; inexact scheduling
  (`inexactAllowWhileIdle`) so no exact-alarm permission is needed — the
  notification may arrive minutes late. Core library desugaring enabled as
  the plugin requires; the launcher icon is kept for R8 (`res/raw/keep.xml`).
  iOS: notification-center delegate in `AppDelegate`.
- Settings (`reminder.enabled`, `reminder.time`) live in `app_settings`.
  The UI state changes only after the system call and the save succeed. An
  enabled reminder is re-created at app start without asking for anything.

## D38 — German pronunciation via system TTS (2026-10-19)

Status: accepted (Phase 5).

- `flutter_tts` 4.2.5 (eyedeadevelopment.com): Android TextToSpeech / iOS
  AVSpeechSynthesizer, `de-DE`, offline when the voice is installed. No
  cloud TTS (would send text to a provider and need keys). Android 11+
  `TTS_SERVICE` query added to the manifest.
- A missing German voice or an engine error is shown as a message.

## D39 — CSV export is an exchange file, not a backup (2026-10-19)

Status: accepted (Phase 5).

- Columns `word, meaning, lemma, part of speech, grammar, example, example
  translation, notes, tags` — exactly the importer's recognized headers, so
  a round trip needs no manual mapping. UTF-8 with BOM, comma, CRLF, RFC 4180
  quoting. Meanings and tags joined with `"; "`.
- Not included: meaning explanations, sentence context, source type,
  enrichment metadata, difficult marks, review events, settings and the API
  key. A `;` inside one meaning splits it on re-import (tested limitation).
  Cells beginning with `=`, `+`, `-` or `@` are not altered (keeps the data
  exact; spreadsheet apps may treat them as formulas).
- Files are saved through `file_picker`'s save dialog (Android
  `ACTION_CREATE_DOCUMENT`, iOS document picker).

## D40 — Anki `.apkg` import and export (2026-10-19)

Status: accepted (Phase 5, after evaluation).

- `archive` 4.5.2 (loki3d.com, MIT; ZIP plus a pure-Dart zstd decoder) and
  `sqlite3` (already used by Drift, now a direct dependency) with a private
  in-memory VFS: packages are read and written without temporary files.
  `crypto` (SHA-1 checksum Anki uses) and `typed_data` were already
  transitive.
- Import: prefers `collection.anki21b` (schema 18, zstd), then
  `collection.anki21`, then `collection.anki2` (schema 11). Registers Anki's
  `unicase` collation (needed to query schema-18 tables) and opens WAL-mode
  copies in rollback mode. Notes become rows of the existing import
  pipeline; the "please update Anki" placeholder is rejected.
- Export: legacy schema 11 `collection.anki2` (importable by current Anki,
  older Anki 2.1 and AnkiDroid), note GUID `aiwortbox-<entry id>`.
- Evidence: fixtures written by the official Anki library 26.09.3; export
  imported by the same library with an exact field/tag check and a
  duplicate-free re-import (`tool/anki/`). The Anki desktop GUI and
  AnkiDroid apps were not run.

## D41 — Free-only OpenRouter usage by default (2026-10-19)

Status: accepted. Refines D29 (model list) and D32 (retries).

- **Zero cost first.** Free-only mode is on by default, also for existing
  installs; paid catalog models are used only after the user turns it off
  and confirms. Free-only requests use `openrouter/free` (Auto Free) or
  models verified free in the live `GET /models` list (Quality Free).
  "Verified free" means: a `:free` id (or the router), prompt and
  completion prices present, every listed price exactly `"0"`, no pricing
  `overrides`, text output, not expired. Zero token prices alone are not
  enough (some paid media models list "0"). If the list cannot be loaded,
  only the free router is used. No plugins are ever requested.
- Three independent guards: model selection above; `provider.max_price`
  of zero on every free request, so OpenRouter refuses priced endpoints;
  and a check of every answer — a reported cost above zero, or an
  answering model that is not recognisably free without a reported zero
  cost, stops the run (`paidModelBlocked`) and nothing is kept.
- **Pacing.** One request at a time, at least 4 s apart (free limit:
  20/min), app-wide (`RequestScheduler`). `Retry-After` and the
  `X-RateLimit-Reset` of a platform 429 are honoured exactly; a wait longer
  than 20 s is not shortened: the request fails with the retry time and
  the scheduler holds further requests until then. Otherwise exponential
  backoff (1 s, 2 s) with up to 50 % jitter. At most 2 retries per batch,
  shared by same-model retries and free-model fallbacks (≤ 3 requests).
- **Daily quota.** A 429 naming the per-day free limit, or a platform 429
  with nothing remaining and a reset more than a minute away, pauses free
  requests until the reset (next 00:00 UTC if not given), persisted across
  restarts. `free_model_daily_requests` from `GET /key` is shown and a
  report of none left also pauses. Limits are only waited for, never
  worked around.
- **Fallback** goes only to other free attempts and only for failures
  another model may fix (404/502/503, 400, 500, unusable answer, a
  provider's own 429). Never for 401/402/403, account rate limits, the
  daily quota, timeouts or network failures (D32 still applies).
- **Batches.** 5 words per request by default (1–10), with ids; answers
  are matched by id *and* echoed word; each word is validated alone, so a
  bad or missing item fails only that word. Strict JSON Schema only where
  the model lists `structured_outputs`; otherwise JSON mode or a prompt
  with the schema, validated the same way. Grammar that cannot be checked
  or contradicts itself is dropped (no note without a word class; nouns
  capitalised with an article; verb lemmas ending in -n).
- **Cache and resume.** Validated results are cached in `app_settings`
  (`aicache.*`, keyed by a hash of word, sentence, existing meanings,
  languages and prompt version; 90 days, 2000 entries), so no answered
  word is sent twice. A deck run is remembered (`ai.job.<deck>`) until
  saved; reopening resumes it, with answered words served from the cache.
  No schema migration: all of this is non-secret key-value state; the key
  stays in secure storage (D28).
- Assumptions (from OpenRouter's documentation, not verified with a live
  account): `max_price` of 0 admits free endpoints; daily free-limit 429s
  carry `X-RateLimit-*` headers with a millisecond reset time; the free
  router honours `require_parameters` for structured outputs.

## D42 — FSRS scheduling is active for review (2026-10-19)

Status: accepted (product owner request; supersedes D35 for scheduled
review).

- Root cause of "FSRS disabled": it was never implemented. `flashcards`
  (schema v1) had the FSRS columns, but no scheduler existed, no code created
  card rows, and practice deliberately bypassed them (D35).
- Library: `fsrs` 2.0.1 (open-spaced-repetition, the version D4 was modelled
  on), default parameters, 90 % desired retention, learning steps 1 and
  10 min, relearning step 10 min, interval fuzzing on.
  `FsrsReviewScheduler` maps "remembered" → Good, "not remembered" → Again
  and stamps `scheduler_version = fsrs-2.0.1;default;retention=0.9`.
- `StudyRepository.recordAnswer` advances the card and inserts the review
  event in **one transaction**. A card row is created on the first
  scheduled answer, so words saved before this change need no backfill and
  `created_at` marks when the card was introduced.
- Due queue (`buildDueQueue`, pure): (re)learning cards due within 20 min,
  review cards due before the end of the local day, then new cards (oldest
  word first) up to the deck's existing daily new-card limit minus cards
  introduced today. 50 cards per session; a card due again within 20 min
  (learning step) returns at the end of the session.
- No schema change: schema stays v2. Existing card rows (e.g. from tests or
  imports) are reused as-is.
- Free practice (any deck, or difficult words only) stays unscheduled
  (D35 rules): it records events, never card state. The manual difficult
  mark is not connected to FSRS.

## D43 — Review direction setting (2026-10-19)

Status: accepted.

- `app_settings['review.direction']` = `germanToPersian` (default when
  missing) | `persianToGerman` | `both`. Chosen on the review setup screen
  or in Settings; applies to every review entry point (Today, deck, setup).
- Each direction is its own card (`flashcards` is unique per entry and
  direction, D4), so switching direction never touches the other
  direction's history.
- Both: a word is asked in one direction per day. Of two due siblings, the
  one due earlier is asked (new words: German → Persian first); a card not
  yet answered today is held back when its sibling was answered today.
  Free practice with both alternates German → Persian and Persian → German.

## D44 — Answers stay hidden until review (2026-10-19)

Status: accepted.

- A deck opens with German words only; meanings are not built (also not
  for screen readers) until "show meanings" is tapped. "Start review" and
  "free practice" are on the deck screen.
- In review only the prompt side of one card is built; the answer card,
  pronunciation of a German answer and its details appear after "Show
  answer". The word page and search keep showing everything (browse mode).

## D45 — German speech on iOS uses the playback audio session (2026-10-19)

Status: accepted (fixes "pronunciation does not work reliably").

- Root cause: `flutter_tts` never configures `AVAudioSession`; iOS then
  uses the default solo-ambient category, which the Ring/Silent switch
  mutes, while `speak` still reports success — so nothing was heard on a
  phone in silent mode and no error was shown.
- Before the first utterance the session is set once to `playback` with
  `duckOthers` (default mode), through the plugin's own channel method
  because the Dart wrapper swallows failures. Other audio is ducked and
  restored after speaking. No recording category, no microphone permission.
- Requests are serialised: a newer tap replaces one not yet started, every
  utterance stops the previous one, `setLanguage` returning 0 means no
  voice. Failures are logged (`ai_wortbox.speech`) and shown as before.

## D46 — Selecting words on the page photo (2026-10-19)

Status: accepted (amends the Phase 3 privacy rule).

- ML Kit word elements (text, box, confidence) are mapped onto the
  normalized OCR text, so the photo view and the text view share one
  `WordSelection`; review, context, duplicates and saving are unchanged.
- Photo view: tap toggles a word; touch-and-hold then drag selects an
  expression (max 10 words, one paragraph); one-finger drag pans, pinch
  zooms (1–8×). `ImageFit` maps image pixels to the screen; the zoom
  transform applies to photo and boxes together.
- Fallback "select area": a drawn box is cropped on the device
  (`dart:ui`, enlarged up to 2× when small), recognized again, shown for
  correction and added as one item. Typed text and the text view remain.
- If boxes do not fit inside the decoded photo (e.g. a rotation mismatch),
  only the text view is offered.
- Privacy: the photo is now kept as a temporary file **while the scan is
  open** (needed to show it) and deleted when the user starts another scan,
  types text instead, goes back, saves, or leaves the screen. Crops are
  deleted right after recognition. Nothing is uploaded.

## D47 — Selecting and deleting several words (2026-10-19)

Status: accepted.

- Long-press a word in a deck or search list to start selection mode; taps
  toggle; select all (the listed words), clear, delete. Changing the search
  or filters clears the selection. Back leaves selection mode.
- Deletion asks for confirmation with the count, then
  `VocabularyRepository.deleteEntries` deletes in one transaction with the
  same rules as a single delete (meanings, tag assignments and card state
  cascade; review events keep their history with `entry_id = NULL`).

## D48 — Manual freehand highlighting on the page photo (2026-10-19)

Status: accepted (product owner request; supersedes D46's selection model).

- Why D46 failed: photos were first read as a whole page, and selection was
  only possible where ML Kit had placed word boxes. Wrong or missing boxes
  made words unselectable or sent the user back to the reformatted text.
- Now a photo opens directly in a highlight screen showing the original
  image (own aspect ratio, letterboxed, never modified). No OCR runs until
  the user taps "Read highlighted text".
- Highlight mode: one finger draws a translucent stroke (a tap marks the
  word under the finger); two fingers zoom/pan. Move mode: one finger pans,
  nothing is drawn. Undo last, remove one (numbered chips), clear all.
- Strokes are stored in photo pixels: screen point → viewer transform
  inverted (`toScene`) → `ImageFit.toImage`. The brush is 20 logical px on
  screen, i.e. 20 / (fit scale × zoom) photo pixels. Device pixel ratio
  does not enter: all mapping is in logical pixels.
- Reading: per stroke, a region = brushed area + padding (≥ 2 % of the
  photo's shorter side vertically, twice that sideways, more for wide
  brushes), clipped to the photo, cropped in memory to a temporary PNG
  (enlarged up to 2× when small), recognized with the existing
  `TextRecognitionEngine`. Only words whose box the finger path ran through
  (its line, reaching the word) are kept, so neighbouring lines inside the
  padding are dropped; without word boxes the small region's text is used.
  An empty region is read once more with double padding, then marked
  failed and reported — the whole page is never read as a fallback.
- Results open in the existing review screen (edit, remove, deck,
  duplicates) plus add a word, split into words, combine with the next, and
  a summary of what will be saved. Only valid, confirmed items are saved.
- Reading the whole page as text remains an explicit menu option, and is
  used automatically only when the photo cannot be decoded for display
  (with a notice).

## D49 — Editing from the review card; the full answer (2026-10-19)

Status: accepted (product owner request).

- Cause of the missing German example: the revealed answer showed only the
  side opposite the prompt. German → Persian showed the Persian side, which
  had only `exampleTranslation`; `exampleSentence` belonged to the German
  side, which was rendered without details as the prompt. The database
  mapping was correct.
- After the reveal, both directions show everything stored: meanings (with
  explanations) or the word, part of speech and grammar, base form, the
  German example (with pronunciation) and its translation, notes, source
  sentence and tags. Empty fields are left out. Nothing is shown before the
  reveal. The card reads the stored entry (`entryProvider`), like the word
  page, so the review UI does not rebuild its own copy.
- "Edit word" (only after the reveal) opens the existing editor on top of
  the session; saving or going back returns to the same card in the same
  phase. Opening, saving or cancelling records no answer; content edits
  never touch `flashcards` or `review_events`.
- The revealed card can also mark or unmark the word as difficult
  (`setDifficult`) and edit its tags (the existing tags sheet). Neither
  records an answer or touches `flashcards`.
- Counter: an FSRS learning-step card due within 20 minutes is appended to
  the session again (intended), but the title used the queue length, so
  "12/61" became "13/62". The title now counts different cards (word +
  direction), so the total stays fixed. A repeated card shows "again in
  this session (learning step)". The progress bar counts cards answered at
  least once.

## D50 — Drawing ignores multi-touch (2026-10-19)

Status: accepted (bug fix for D48).

- Cause: strokes were driven by the scale recognizer. When a finger is
  added or lifted it ends the gesture and starts a new one. A second finger
  therefore committed the partial stroke, and lifting one finger of a pinch
  started a stroke from `_downAt`. `_downAt` held the position of the last
  finger that touched down (the other finger), so a long line was drawn
  between the fingers.
- Now drawing follows raw pointer events by pointer id. Only the finger
  that started a draft extends it. The draft is kept only when that finger
  lifts with no other finger having touched meanwhile. Any second finger
  discards the draft, and nothing is drawn until all fingers are up.
  Cancelled pointers discard the draft. The scale recognizer only zooms and
  pans, and only with two or more fingers. Move mode is unchanged.

## D51 — Rectangle selection on the page photo (2026-10-19)

Status: accepted (product owner request).

- A third mode, next to highlight and move: one finger drags a rectangle.
  Drags smaller than 12 logical px on screen are ignored. Two fingers zoom.
  Rectangles are stored in photo pixels (screen → inverse viewer transform
  → `ImageFit.toImage`) and clipped to the photo. They are drawn as an
  overlay. They are numbered with the highlights, and undo, remove and clear
  apply to both.
- Reading: each rectangle is cropped exactly (no padding) into a temporary
  PNG and recognized with the existing on-device engine. That PNG is
  deleted afterwards, and the photo file is never changed. Every recognized
  line with words becomes one review item, in the recognizer's reading
  order. A word hyphenated across lines is joined. The context is the
  sentence within the rectangle. No word boxes are needed.
- An empty rectangle is marked failed and reported ("draw the rectangle
  again"). The whole page is never read as a fallback. Nothing is
  translated or enriched; only confirmed items are saved.

## D52 — Memory Coach, first version: a fixed rule (2026-10-19)

Status: accepted (product owner request). Not a prediction or AI model.

- Rule (`MemoryCoachRule.standard`): for each word, take its answers from
  the last 30 days, newest first, at most 8 (both directions). The word
  needs practice when its "not remembered" answers in that window come from
  at least 2 different review sessions, and its latest 3 answers are not
  all "remembered".
- So words without history, and a new word forgotten twice in its first
  session, never qualify; three correct answers in a row remove a word.
- Data: existing `review_events` only (scheduled and free-practice answers
  alike, since the table does not separate them). There is no new table or
  migration.
- Opening the list or a word reads only. Focused practice is free practice:
  answers are stored as review events (history and statistics, and they let
  a word recover) and never change `flashcards`, so FSRS due dates and
  state are unaffected. It respects the review direction setting.
- Entry point: "Needs practice" on Today. This is separate from the manual
  "difficult" mark.

## D53 — Missing-meaning filter and batch AI meanings for selected words (2026-10-20)

Status: accepted (product owner request). Extends D41 batching; no new
provider, backend or paid default.

- Missing meaning = no meaning row whose text is non-blank after trimming
  (Dart `String.trim` whitespace, mirrored in SQL). Examples, notes and
  grammar do not count. `VocabularyQuery.missingMeaningOnly` (SQL
  `NOT EXISTS`) and `VocabularyEntry.lacksMeaning` apply the same rule.
- Selection mode gains "AI meanings for selected"
  (`EnrichmentTarget.selection`, route `/words/enrich`, ids in `extra`).
  Only selected entries that lack a meaning are sent; the others are counted
  and shown as left out, so existing meanings can never be overwritten
  (overwrite is not offered). At most `aiMaxBatchSize` (50) per run; the
  rest is reported. Selection runs are not stored as resumable jobs.
- Scope `EnrichmentScope.meanings`: its own system prompt and strict schema
  (`id`, `word`, `meanings`, `isAmbiguous`), `max_tokens` 200 + 250 per word,
  always the batch format (even for one word). Other fields in an answer are
  discarded. Cache keys include the scope, so meanings-only and full results
  never answer each other; existing full keys are unchanged.
- Batch size: the existing "words per request" setting (default 5, 1–10).
  Five keeps one malformed answer from failing many words and stays well
  inside free models' output limits; a batch is also cut at 4000 input
  characters (`aiMaxBatchInputChars`), one long word still goes alone.
- Validation: answers are matched by id and echoed word; unknown ids are
  ignored; a word answered twice (duplicate id) is now rejected for that
  word (was: first answer wins); missing, empty or invalid meanings fail that
  word only. An answer unusable as a whole (invalid or cut-off JSON) is sent
  once more as two halves (the model did answer, so nothing is ambiguous);
  timeouts and network errors are still never re-sent automatically.
- `EnrichmentJobRegistry` (in memory) holds the ids a running session is
  requesting; another session marks such words `EnrichmentError.busy`
  instead of sending them. Ids are released when the run ends, is cancelled
  or the screen closes.
- Review: each suggested meaning can be edited (blank or over-long text is
  refused; edits that repeat a meaning are dropped), accepted or rejected.
  Saving uses `applyEnrichments` unchanged (adds meanings only, optimistic
  `updatedAt` check, never touches `flashcards` or `review_events`).
- Request count: 10 eligible words need 2 requests at the default size (1
  at size 10) instead of 10. This cuts round trips and free-tier request
  usage; token cost on paid models depends on the text sent and returned,
  so no fixed saving is claimed.
- The "Clear filters" chip now comes first in the chip row so it stays
  visible on narrow screens.

## D54 — Full backup and restore (2026-10-20)

Status: accepted (product owner request for Build 3; approves P3's backup
part and follows D19).

- Format: one versioned UTF-8 JSON file (`docs/backup-format.md`), not a
  copy of the SQLite file: it is validated field by field, independent of
  the schema version and readable by a person. `formatVersion` 1, the
  schema version, app version/build, export time, counts and a SHA-256
  checksum of the data. No ZIP: there are no media files yet.
- Contents: every learning table with ids (decks, entries, meanings,
  flashcards with the full FSRS state, tags, tag assignments, review
  events incl. those of deleted words, sentence-practice history).
  Excluded: the API key (never in the database) and all of `app_settings`
  — restoring AI preferences could silently turn free-only mode off, and
  reminders/review direction are device settings.
- Validation before any write (`BackupCodec.decode`): types, enums, UTC
  dates, ranges, unique ids and unique values, references, counts,
  checksum, format and schema version. Background isolate above 256 KB.
- Two modes, chosen after a preview of file vs. device counts: **merge**
  (adds only; matched by id, deck/tag by name, words by the existing
  duplicate rule; a word already present keeps its own FSRS state) and
  **replace** (explicit confirmation dialog stating what is deleted).
- Safety: a safety copy of the current data is written first (newest three
  kept in the app support directory, restorable from the same screen); if
  it cannot be written nothing is restored. The restore itself is one
  transaction, so a failure leaves the database unchanged (tested with a
  forced foreign-key failure).
- Saving uses the existing export save dialog; choosing a file uses
  `file_picker` (100 MB limit). No new dependency; `crypto` was already
  used.
- Not done: encryption, automatic periodic backups, cloud upload.

## D55 — AI sentence practice (2026-10-20)

Status: accepted (product owner request for Build 3).

- Separate from scheduled review: it never reads or writes `flashcards`
  or `review_events`, so FSRS state, due dates, statistics and streaks are
  unaffected (widget test compares those tables before and after a
  session). It never creates or edits vocabulary.
- Words: entries with at least one non-blank meaning, optionally limited
  to a deck and/or tag. Order (`selectPracticeWords`): words practised in
  sentences within 3 days last; before them words marked difficult or
  flagged by the Memory Coach rule (D52); then never practised, then the
  longest ago; ties shuffled.
- Directions: *write* (a Persian sentence is shown with the German target
  word; the learner writes German) and *understand* (a German sentence is
  shown; the learner writes its Persian meaning). Levels A2/B1/B2; 3, 5
  or 8 words per session.
- Requests: one request generates the whole session (words with base
  form, word class and saved meanings only); one request checks one answer
  (word, meanings, the sentence shown, the model answer, the learner's
  answer). Both only on an explicit tap. Model answers stay hidden until the
  learner checks an answer or taps "Show model answer".
- AI policy: the free-only request loop (plan attempts, zero `max_price`,
  zero-cost check of every answer, free-only fallback, shared retry budget)
  moved unchanged from `OpenRouterEnrichmentService` into `OpenRouterChat`,
  which both features use with the same client (pacing, rate limits, daily
  quota, D32), key store and preferences. No new key storage, model list or
  configuration; the existing enrichment tests pass unchanged.
- Validation: strict JSON Schema where supported; every item is matched by
  id and echoed word; the German sentence must contain the reported form
  and `TargetWordMatcher` must recognise it as the word (case/umlaut-
  insensitive stems, separable prefixes, the curated irregular forms of
  D25); the Persian text must be Persian and contain no German words.
  Invalid items are left out and reported; an unusable answer is malformed
  (fallback per D41). Feedback must have a known verdict and target-word
  status, a Persian explanation, and must not call an answer correct when
  the target word is missing or misused. "acceptable" (a valid alternative)
  is never an error.
- Failures: generation errors show a recoverable state ("Try again" sends
  a new request); a failed check keeps the typed answer.
- History: schema v3 adds `sentence_practice_events` (id, entry, direction,
  level, outcome, time; cascade on word delete). No answers or AI text are
  stored. It can be cleared alone (confirmation) and is included in
  backups. Additive migration, tested from real v2 data.
- Limitations: the target-word check is heuristic (an unrecognised
  irregular form drops that exercise; a word that merely contains the stem
  may pass); feedback quality depends on the free model; no live OpenRouter
  call has been made from this project.

## D56 — Installed version and release notes in the app (2026-10-20)

Status: accepted (product owner requirement for every release).

- Settings → About AI WortBox shows the installed version and build read
  from the platform with `package_info_plus` 10.2.2 (fluttercommunity.dev,
  Flutter Favorite, iOS and Android; 150/160 pub points on 2026-10-20). It
  replaces nothing; no hard-coded version in the UI.
- Release notes live in `assets/release_notes.json` (Persian and English,
  per build, optional accurate date), process in `docs/releases.md`. The
  screen shows only the installed build's notes ("no notes recorded"
  otherwise) and states that it describes the installed build; the app
  does not check for updates.
- A test ties `pubspec.yaml`'s version/build to the notes, so a release
  without notes fails the test suite.
- `AiWortBoxApp` takes an optional locale (default Persian) so tests
  verify the English LTR layout; the shipped UI stays Persian (D8).
