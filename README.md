# AI WortBox

**From Book Pages to Lasting Memory.** — *Von der Buchseite ins Gedächtnis.*

AI WortBox is a local-first iOS/Android app (Flutter) that helps Persian
speakers learn German vocabulary: collect words from CSV files, manual entry or
scanned book pages, enrich them with AI-generated Persian meanings, and review
them with FSRS spaced repetition.

> The name "AI WortBox" has not been checked for trademark or app-store
> availability.

## Status

| Phase | Scope | Status |
| --- | --- | --- |
| 1 | Foundation, navigation, Drift database, decks | **Complete** (`73fa370`) |
| 2 | Manual vocabulary entry, CSV import | **Implemented — awaiting commit** |
| 3 | Photo/gallery input, German OCR, word selection | **Implemented — awaiting commit** |
| 4 | AI enrichment via secure backend (OpenRouter) | Planned |
| 5 | FSRS review and release preparation | Planned |

Additional features (search filters, tags, backup/restore, reminders,
streaks, text-to-speech, images, Anki interoperability and more) are recorded
as **proposed — not approved** in the
[roadmap](docs/implementation-plan.md#proposed-feature-register-not-approved).
They are not implemented and will not be without explicit approval.

See [docs/implementation-plan.md](docs/implementation-plan.md) and
[docs/claude-phase-instructions.md](docs/claude-phase-instructions.md).

## What works today (Phases 1–2)

- Persian, right-to-left UI with five tabs: Today (مرور امروز), My Words
  (لغات من), Add Vocabulary (افزودن لغت), Statistics (آمار), Settings (تنظیمات).
- Creating and listing decks; decks default to German → Persian and persist
  in a local SQLite database.
- Vocabulary entries: create, view, edit, delete and search; multiple Persian
  meanings, German example + Persian translation, grammar, part of speech,
  base form and notes. German fields are left-to-right, Persian fields
  right-to-left. Works fully offline.
- Duplicate detection per deck that never merges different meanings without
  asking.
- CSV import: file picker, UTF-8 / UTF-8 BOM / UTF-16 (BOM), automatic or
  manual delimiter (`,` `;` tab `|`), header recognition (English, German,
  Persian), column mapping, language confirmation, row-level errors with line
  numbers, three duplicate strategies, preview, and an all-or-nothing
  transactional import.
- Review state (flashcards) is never modified by editing vocabulary.

## Platform build status

iOS and Android builds are **not yet verified**. The development machine used
so far has no Android SDK and no full Xcode installation, so
`flutter build apk` and `flutter build ios` could not run. Verification so far
is limited to formatting, static analysis and host-side automated tests
(including widget tests of the full UI flows). The native file picker
(`file_picker`) in particular has not been exercised on a device.

## CSV format

UTF-8 (with or without BOM) or UTF-16 with BOM; delimiter `,` `;` tab or `|`.
A header row is optional. Recognized headers include `word`, `term`,
`german`, `meaning`, `translation`, `persian`, `example`, `example
translation`, `grammar`, `notes` (plus German and Persian equivalents such as
`Wort`, `Bedeutung`, `لغت`, `معنی`). Several meanings in one cell can be
separated with `;`, `؛` or `|`. Limits: 5 MB and 10,000 rows per file.

```csv
word,meaning,example,example translation
Haus,خانه,Das Haus ist groß.,خانه بزرگ است.
aufgeben,"تسلیم شدن؛ ترک کردن",Er gibt nie auf.,او هرگز تسلیم نمی‌شود.
```

## Requirements

- Flutter 3.47 stable (Dart 3.13) or newer
- For Android builds: Android Studio + Android SDK
- For iOS builds: macOS with full Xcode and CocoaPods

## Setup

```sh
flutter pub get          # also generates localizations (lib/l10n)
flutter run              # on a connected device or simulator
```

Generated code (Drift `*.g.dart`, localizations) is committed. Regenerate after
changing tables or ARB files:

```sh
dart run build_runner build   # Drift
flutter gen-l10n              # localizations
```

## Quality checks

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

See [docs/testing.md](docs/testing.md) for what is covered.

## Documentation

- [Implementation plan and roadmap](docs/implementation-plan.md)
- [Phase working instructions](docs/claude-phase-instructions.md)
- [Architecture](docs/architecture.md)
- [Decisions](docs/decisions.md)
- [Testing](docs/testing.md)

## Privacy

All data is stored on the device. No account is required. AI enrichment
(Phase 4) will send only selected words and their sentence context to a
backend you control; API keys never ship in the app.
