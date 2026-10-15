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
