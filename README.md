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
| 2 | Manual vocabulary entry, CSV import | **Complete** (`bbc9877`) |
| 3 | Photo/gallery input, German OCR, word selection | **Complete** (`77287d7`) |
| 4 | AI enrichment with your own OpenRouter key | **Implemented — awaiting commit** (live API and device checks outstanding) |
| 5 | FSRS review and release preparation | Planned |

Additional features (search filters, tags, backup/restore, reminders,
streaks, text-to-speech, images, Anki interoperability and more) are recorded
as **proposed — not approved** in the
[roadmap](docs/implementation-plan.md#proposed-feature-register-not-approved).
They are not implemented and will not be without explicit approval.

See [docs/implementation-plan.md](docs/implementation-plan.md) and
[docs/claude-phase-instructions.md](docs/claude-phase-instructions.md).

## What works today (Phases 1–3)

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

### Page scanning (Phase 3)

- Scan a book page: take a photo or choose one from the gallery; German text
  is recognized **on the device** (Google ML Kit, no internet, the photo is
  deleted right after recognition).
- Select single words or multi-word expressions in the recognized text
  (shown left-to-right inside the Persian UI); correct OCR mistakes; the
  original sentence is kept as context for each word.
- Review screen listing exactly what will be saved, with optional Persian
  meaning, optional base form and cautious offline base-form hints for common
  irregular verbs (never applied automatically).
- Typed-text fallback when OCR fails, finds nothing or is unavailable.
- Saves only confirmed items, to a chosen deck, in one transaction, with the
  same duplicate rules as CSV import.

### Phase 4 — implemented, awaiting commit

- AI suggestions with **your own OpenRouter key** (bring your own key):
  usage is billed to your OpenRouter account. The key is stored only in the
  device's secure storage (iOS Keychain / Android Keystore-protected
  storage), and the app calls OpenRouter directly over HTTPS. There is no
  backend or proxy.
- Suggestions for a deck's words without meanings, or for one word on
  request: Persian meanings using the sentence context, a German example with
  Persian translation, grammar notes, an optional base form. Nothing is saved
  until you review it; existing meanings and review state are never changed.
- Only tested with mocked HTTP so far: **no live OpenRouter call and no
  real-device test has been made yet.**

## Platform build status

iOS and Android builds are **not yet verified**. The development machine used
so far has no Android SDK and no full Xcode installation, so
`flutter build apk` and `flutter build ios` could not run. Verification so far
is limited to formatting, static analysis and host-side automated tests
(including widget tests of the full UI flows). The native file picker
(`file_picker`) in particular has not been exercised on a device.

Phase 3 adds native plugins (`image_picker`, `google_mlkit_text_recognition`)
and raises the iOS minimum to 15.5. Camera, gallery and OCR are tested only
with fakes so far; they must be checked on real devices (see
[docs/testing.md](docs/testing.md)).

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

All data is stored on the device. No account is required. AI suggestions
(Phase 4) are optional: only when you ask, the app sends the selected word,
its sentence context and its existing meanings directly to OpenRouter, using
your own key from the device's secure storage. No API key ships in the
app.
