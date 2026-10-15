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
