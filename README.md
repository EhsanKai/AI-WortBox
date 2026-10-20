# AI WortBox

**From Book Pages to Lasting Memory.** — *Von der Buchseite ins Gedächtnis.*

AI WortBox is a local-first iOS/Android app (Flutter) that helps Persian
speakers learn German vocabulary: collect words from CSV files, manual entry or
scanned book pages or Anki packages, enrich them with AI-generated Persian
meanings, and review them with FSRS spaced repetition (German → Persian by
default, Persian → German or both).

> The name "AI WortBox" has not been checked for trademark or app-store
> availability.

## Install

- **[Installation guide](docs/installation.md)**: build it onto your own
  iPhone with Xcode, distribute it through TestFlight, set up the optional
  OpenRouter key, and troubleshoot.
- Current release: **1.0.0, build 4** ([release notes](assets/release_notes.json),
  [release process](docs/releases.md)). In the app: Settings → About AI
  WortBox shows the installed version, build and its changes.
- TestFlight status: **not yet available.** Uploading needs a paid Apple
  Developer Program account; see [the remaining steps](docs/installation.md#b-install-through-testflight).

## Status

| Phase | Scope | Status |
| --- | --- | --- |
| 1 | Foundation, navigation, Drift database, decks | **Complete** (`73fa370`) |
| 2 | Manual vocabulary entry, CSV import | **Complete** (`bbc9877`) |
| 3 | Photo/gallery input, German OCR, word selection | **Complete** (`77287d7`) |
| 4 | AI enrichment with your own OpenRouter key | **Complete** (`eaa0278`); live OpenRouter and real-device/platform verification outstanding |
| 5 | Search, tags, CSV export, Anki import/export, German TTS, study reminder, practice, statistics, difficult words | **Implemented — awaiting commit**; platform builds and real-device checks outstanding |

Since Phase 5: FSRS-scheduled review with a choice of direction, answers
hidden until review, word selection directly on the page photo, reliable
German pronunciation on iOS, and selecting/deleting several words
(D42–D47).

Build 3 (`1.0.0+3`, D54–D56): full backup and restore, the About screen
with release notes, and AI sentence practice.

Not implemented: images, and the other items recorded as **proposed — not approved** in the
[roadmap](docs/implementation-plan.md#proposed-feature-register).

See [docs/implementation-plan.md](docs/implementation-plan.md) and
[docs/claude-phase-instructions.md](docs/claude-phase-instructions.md).

## What works today (Phases 1–5)

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

- Scan a book page: take a photo or choose one from the gallery. The photo
  is shown exactly as taken; **highlight the words you want with your
  finger** (pinch to zoom, undo, clear). Only the highlighted parts are
  recognized **on the device** (Google ML Kit, no internet), then shown for
  correction before saving. The photo is kept only while the scan is open.
  Reading the whole page as text is an explicit menu option (D48).
- Select single words or multi-word expressions in the recognized text
  (shown left-to-right inside the Persian UI); correct OCR mistakes; the
  original sentence is kept as context for each word.
- Review screen listing exactly what will be saved, with optional Persian
  meaning, optional base form and cautious offline base-form hints for common
  irregular verbs (never applied automatically).
- Typed-text fallback when OCR fails, finds nothing or is unavailable.
- Saves only confirmed items, to a chosen deck, in one transaction, with the
  same duplicate rules as CSV import.

### AI suggestions (Phase 4, `eaa0278`)

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

### Missing meanings: batch AI meanings (D53)

- **Missing meaning** filter in the word lists (blank or whitespace-only
  meanings count as missing; examples or notes do not count as a meaning).
  Combines with search, tags and difficult words.
- Select several words (long-press, select all, clear) → **AI meanings for
  selected**: only the selected words without a meaning are sent, several
  per request (5 by default, 1–10 in Settings → AI), and only Persian
  meanings are requested. Words that already have a meaning are left out
  and never changed.
- Answers are matched by id, validated, and reviewed before saving: each
  suggestion can be edited, accepted or rejected. A failed word fails
  alone; retry sends only failed words. Saving never touches review state.

### Phase 5 — implemented, awaiting commit

- **Search and filters:** search all words (My Words → search) or one deck by
  German word, base form or Persian meaning; filter by tag and by difficult
  words. Persian letter variants, diacritics and the ZWNJ are ignored.
- **Tags:** several per word; create, rename and delete (deleting a tag never
  deletes words). CSV and Anki imports bring their tags along.
- **Difficult words:** mark a word on its page; badge in lists; filter;
  practise only difficult words. Marking is manual only.
- **Pronunciation:** play the German word and example with the device's own
  text-to-speech voice (works offline if a German voice is installed).
- **Review (FSRS):** due cards one at a time, prompt side only; reveal the
  answer, then record "remembered" or "not remembered", which sets the next
  review with FSRS. Direction: German → Persian (default), Persian →
  German, or both. Free practice (all words or difficult words only) does
  not change the schedule.
- **Decks hide meanings** until you tap "show meanings"; long-press words to
  select several and delete them after confirmation.
- **Statistics:** words, difficult words, recorded answers, sessions, study
  days, current and longest streak, the last 14 days — only from answers you
  recorded in practice. A day is midnight to midnight on the device clock.
- **Study reminder:** one daily local notification at a time you choose
  (Settings → Study reminder). Permission is asked only when you turn it on.
- **Export:** a deck as CSV or as an Anki package (`.apkg`), saved where you
  choose.
- **Anki import:** Add → Import from Anki (`.apkg`), through the same
  preview and duplicate handling as CSV.

### Build 4 (1.0.0+4)

- **Sentence practice fix:** requests to the free models (all of which
  "think" before answering) now leave room for an answer and keep the
  thinking short; answers with extra text are accepted and partly valid
  answers keep their good exercises. If generation still fails, the error
  says why and "Technical details" shows what happened (no key, none of
  your words). Not yet confirmed with a real OpenRouter request.
- **Card appearance** (word page or review card → Card appearance):
  background and text colour, separate sizes for the German word and the
  meanings, highlighted words or meanings, and a sticker, per word, with a
  live preview, Save, Cancel and Reset. Included in backups; never changes
  the word, its review schedule or history.

### Build 3 (1.0.0+3)

- **Backup and restore** (Settings → Backup and restore): one JSON file
  with all decks, words, meanings, tags, the FSRS review schedule, review
  history and sentence-practice history. Restore checks the whole file
  first, shows what it contains, then either **adds** what is missing
  (nothing on the device is changed or deleted) or **replaces** everything
  after an explicit confirmation. A safety copy of the current data is
  saved first and the restore is all-or-nothing. Your OpenRouter key and
  settings are never in a backup. Format: [docs/backup-format.md](docs/backup-format.md).
- **About AI WortBox** (Settings): installed version, build number and the
  changes in this build (Persian/English).
- **AI sentence practice** (Today): write a Persian sentence in German with
  a target word, or write the meaning of a German sentence in Persian;
  levels A2–B2; 3, 5 or 8 of your own words (difficult, struggling and not
  recently practised words first); feedback on the target word, grammar,
  word order, spelling and capitalization, a natural version and a Persian
  explanation; the model answer appears only after you answer or ask for
  it. Uses your OpenRouter key with the same free-only rules as AI
  suggestions. It never changes the FSRS schedule, review history or
  statistics; only which word was practised, when and how it went is
  saved.

### CSV export is not a backup

The CSV file contains each word, its meanings, base form, part of speech,
grammar, example and translation, notes and tags. It does **not** contain
meaning explanations, sentence context, difficult marks, practice history and
statistics, settings, or your API key (never exported). It is meant for
spreadsheets, other apps and re-importing words. For a full backup use
Settings → Backup and restore.

## Platform build status

iOS: `flutter build ios --release` and a release archive
(`flutter build ipa`) build with Xcode 26; the app has been installed on an
iPhone with development signing. App Store/TestFlight export needs a paid
Apple Developer account (see [installation](docs/installation.md)).
Android builds are **not yet verified** (no Android SDK on the development
machine), so `flutter build apk` could not run. Verification so far
is limited to formatting, static analysis and host-side automated tests
(including widget tests of the full UI flows). The native file picker
(`file_picker`) in particular has not been exercised on a device.

Phase 3 adds native plugins (`image_picker`, `google_mlkit_text_recognition`)
and raises the iOS minimum to 15.5. Camera, gallery and OCR are tested only
with fakes so far; they must be checked on real devices (see
[docs/testing.md](docs/testing.md)).

Phase 5 adds `flutter_tts`, `flutter_local_notifications` (Android: core
library desugaring, notification permission and boot receiver; iOS:
notification delegate) and `flutter_timezone`. Text-to-speech, notifications
and the save dialogs are tested only with fakes; none has run on a device.

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

A `tags` column (several tags separated by `;`) is also recognized.

**Export** (deck menu → Export as CSV) writes UTF-8 with BOM, comma-separated,
with the columns `word, meaning, lemma, part of speech, grammar, example,
example translation, notes, tags`; several meanings or tags are joined with
`; `. Importing the file again maps every column automatically. A meaning
that itself contains `;` is split into two meanings on re-import.

## Anki

- **Import** (Add → Import from Anki): `.apkg` packages from current Anki
  (2.1.50 and later, including "support older Anki versions" exports) and
  older/legacy packages. Every note's fields become columns you map to word,
  meaning, etc. (`Front`/`Back` are mapped automatically); tags are kept.
  Images, audio, scheduling and deck hierarchy are not imported. Limit: 50 MB
  and 10,000 notes.
- **Export** (deck menu → Export for Anki): an `.apkg` with the note type
  "AI WortBox (German → Persian)" (one German → Persian card per word, tags
  included, Persian right-to-left). Cards arrive as new cards; no scheduling
  is exported. Exporting again later updates the same notes in Anki instead
  of duplicating them.
- Verified with the official Anki library 26.09.3 (see
  [tool/anki/README.md](tool/anki/README.md)); the Anki desktop app,
  AnkiDroid and AnkiMobile themselves have not been tested.

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

- [Installation and TestFlight](docs/installation.md)
- [Releases: version, build and release notes](docs/releases.md)
- [Backup file format](docs/backup-format.md)
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
app. Phase 5 features (search, tags, practice, statistics, reminders,
text-to-speech, export and Anki import) work entirely on the device;
exported files and backups contain no settings or keys. AI sentence
practice sends only the practised words, their saved meanings, the
exercise sentence and (when you check it) your answer, only when you tap.
