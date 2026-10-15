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
| 1 | Foundation, navigation, Drift database, decks | **Done (approved)** |
| 2 | Manual vocabulary entry, CSV import | Not started |
| 3 | Book scanning (OCR) and word selection | Not started |
| 4 | OpenRouter AI enrichment via secure backend | Not started |
| 5 | FSRS review, statistics, release readiness | Not started |

See [docs/implementation-plan.md](docs/implementation-plan.md).

## What works today (Phase 1)

- Persian, right-to-left UI with five tabs: Today (مرور امروز), My Words
  (لغات من), Add Vocabulary (افزودن لغت), Statistics (آمار), Settings (تنظیمات).
- Creating and listing decks; decks default to German → Persian and persist
  in a local SQLite database.
- Complete v1 database schema for decks, vocabulary entries, meanings and
  flashcards/review state (feature logic for the last three follows in later
  phases).

## Platform build status

iOS and Android builds are **not yet verified**. The development machine used
so far has no Android SDK and no full Xcode installation, so
`flutter build apk` and `flutter build ios` could not run. Verification so far
is limited to formatting, static analysis and host-side automated tests.

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

- [Implementation plan](docs/implementation-plan.md)
- [Architecture](docs/architecture.md)
- [Decisions](docs/decisions.md)
- [Testing](docs/testing.md)

## Privacy

All data is stored on the device. No account is required. AI enrichment
(Phase 4) will send only selected words and their sentence context to a
backend you control; API keys never ship in the app.
