# Design system

AI WortBox — «از صفحه کتاب تا یادگیری ماندگار»

The app's visual identity: a book page dropping into a warm yellow
**vocabulary box**. Deep navy carries structure and type, warm cream is the
paper the app is printed on, and mint is a small, restrained accent for
assistance (hints, AI status) and success. Quality comes from typography,
spacing and hierarchy, not from gradients, shadows or decorative cards:
surfaces are flat and separated by hairlines.

Code: `lib/core/design/` (tokens, colors, typography), `lib/app/theme.dart`
(both themes), `lib/core/widgets/` (shared components).

## Brand motifs

| Motif | Where |
| --- | --- |
| Brand mark (page into box, mint spark), drawn in code | Today header, scan intro, settings/about, license page |
| Yellow "box" tile behind an icon | Deck tiles, Add-tab choices, the selected navigation tab, floating actions |
| Yellow section marker (a short vertical bar) | Every section header |
| Highlighter stroke | Selected words on a scanned page, meaning numbers |
| Paper surface with a yellow edge | Example sentences and the scanned-page context |

## Tokens

### Color (semantic)

| Role | Light | Dark |
| --- | --- | --- |
| Background (`surface`) | cream `#FBF7EE` | navy `#0D1424` |
| Card / sheet / dialog (`surfaceContainerLow`) | paper `#FFFDF8` | `#141D31` |
| Text (`onSurface`) | navy `#15213B` | cream `#F4EFE3` |
| Secondary text (`onSurfaceVariant`) | slate `#4F5870` | `#B3BACB` |
| Primary action (`primary`) | navy `#1B2B4B` on cream text | yellow `#F4C04A` on navy text |
| Brand box (`AppColors.box`) | yellow `#F2B630` | yellow `#F4C04A` |
| Highlight (selected word) | `#FCE39A` | `#F4C04A` |
| Accent (`tertiary`, mint) | `#0F6B55` | `#63D6B6` |
| Error | `#B42318` | `#FFB4A9` |
| Hairline (`outlineVariant`) | `#E3D9C4` | `#2B3856` |
| Field outline (`outline`) | `#857C69` | `#7D89A6` |

Status tones (`StatusTone`: neutral, success, warning, danger, accent) each
have a foreground/background pair in `AppColors`. They are used by
`StatusBadge`, `InfoBanner` and empty states, always together with text:
color is never the only signal.

All text/background pairs meet WCAG AA 4.5:1 and field outlines meet 3:1 in
both themes. This is enforced by `test/core/design/contrast_test.dart`.

### Spacing, radius, borders, elevation, icons, touch

| Token | Values |
| --- | --- |
| `AppSpace` | 2 · 4 · 8 · 12 · 16 (page gutter) · 24 · 32 · 48; 96 FAB clearance |
| `AppRadius` | 6 · 10 · 14 (buttons, fields) · 18 (cards) · 24 (dialogs, sheets) · pill |
| `AppBorder` | hairline 1 · emphasis 1.5 · focus 2 |
| `AppElevation` | flat 0 (all surfaces) · floating 2 (FAB) · overlay 3 (dialogs) |
| `AppIconSize` | 18 · 24 · 32 · 48 |
| `AppTouch` | minimum target 48 · button height 52 |
| `AppMotion` | 120 ms · 200 ms |

### Typography

| Style | Font | Size / line height | Use |
| --- | --- | --- | --- |
| `headword` | Literata SemiBold | 30 / 1.25 | German word on its detail screen |
| `wordTitle` | Literata SemiBold | 19 / 1.3 | German word in lists, cards, dialogs, the word field |
| `germanBody` | Literata Regular | 17 / 1.55 | Example sentences, page context, German input |
| `pageText` | Literata Regular | 19 / 1.4 | Words on the scanned page |
| `headlineSmall`…`titleSmall` | Vazirmatn Bold/Medium | 22–14 / 1.4–1.5 | Persian headings |
| `bodyLarge`…`bodySmall` | Vazirmatn Regular | 16–13 / 1.7–1.6 | Persian body text and meanings |
| `label*` | Vazirmatn Medium | 15–12 / 1.4 | Buttons, badges, navigation |

Persian line heights are deliberately generous, for the dots and marks of
the Arabic script. The German headword is always the most prominent element,
and Persian meanings are set at body-large size directly below it.

## Fonts and licensing

| Family | Files (bundled) | Size | Source | License |
| --- | --- | --- | --- | --- |
| Vazirmatn 33.003 | `Vazirmatn-Regular/Medium/Bold.ttf` (400/500/700) | ~113 KB each | [google/fonts `ofl/vazirmatn`](https://github.com/google/fonts/tree/main/ofl/vazirmatn) (upstream: rastikerdar/vazirmatn) | SIL OFL 1.1, no Reserved Font Name |
| Literata 3.103 | `Literata-Regular.ttf` (400), `Literata-SemiBold.ttf` (600) | ~62 KB each | [google/fonts `ofl/literata`](https://github.com/google/fonts/tree/main/ofl/literata) (TypeTogether) | SIL OFL 1.1, no Reserved Font Name |

Total: about 464 KB. The license texts are bundled
(`assets/fonts/OFL-*.txt`) and registered with `LicenseRegistry`, so they
appear on the license page (Settings → licenses).

Why these fonts:

- **Vazirmatn** is designed for Persian UI text. It has full Persian letter
  and digit coverage («» ، ؛ ؟ and ZWNJ included) and a matching Latin, so
  mixed UI strings look consistent.
- **Literata** is a book face (originally made for Google Play Books). It
  fits the "from the book page" idea and keeps ä ö ü ß ẞ and „…“ quotes
  clear at small sizes.

How the files were made (static instances avoid relying on variable-font
weight mapping in Flutter; Literata is subset because only Latin is needed):

```sh
pip install fonttools==4.55.3
# Vazirmatn: one static instance per weight, all glyphs kept.
fonttools varLib.instancer 'Vazirmatn[wght].ttf' wght=400 -o Vazirmatn-Regular.ttf  # also 500, 700
# Literata: instance at weight/optical size, then subset to Latin.
fonttools varLib.instancer 'Literata[opsz,wght].ttf' wght=400 opsz=16 -o lit-400.ttf
fonttools varLib.instancer 'Literata[opsz,wght].ttf' wght=600 opsz=28 -o lit-600.ttf
pyftsubset lit-400.ttf --output-file=Literata-Regular.ttf \
  --unicodes='U+0020-007E,U+00A0-00FF,U+0100-017F,U+0218-021B,U+02BC,U+02C6,U+02DA,U+02DC,U+1E9E,U+2009-200A,U+2010-2015,U+2018-201E,U+2020-2022,U+2026,U+2030,U+2039-203A,U+20AC,U+2122,U+2212' \
  --layout-features='kern,liga,clig,calt,ccmp,locl,mark,mkmk,lnum,pnum,tnum,case' \
  --name-IDs='*' --name-legacy --name-languages='*'   # same for lit-600
```

The OFL permits modified versions (instancing, subsetting) under the same
license. Neither font declares a Reserved Font Name.

Each German style falls back to Vazirmatn, and the UI style to Literata.
Vazirmatn lacks only the capital ẞ, which German styles render with
Literata.

## Components

| Component | File | Purpose |
| --- | --- | --- |
| `BrandMark` | `core/widgets/brand_mark.dart` | The logo, painted in code (no image assets) |
| `SectionHeader` | `core/widgets/section_header.dart` | Section title with the yellow marker; a semantic header |
| `ActionTile` | `core/widgets/action_tile.dart` | Large choice tile (Add tab, settings); `DirectionalChevron` |
| `StatusBadge` | `core/widgets/status_badge.dart` | Pill for item status (new, merge, duplicate, error, AI status) |
| `InfoBanner` | `core/widgets/info_banner.dart` | Inline error, warning, privacy, hint or suggestion; errors are live regions |
| `EmptyStateView`, `ErrorStateView`, `LoadingView`, `ButtonProgress` | `core/widgets/state_views.dart` | Empty, error, loading and in-button busy states |
| `OutcomeView` | `core/widgets/outcome_view.dart` | Success summary after a CSV import or a scan save |
| `EntryTile` | `features/vocabulary/presentation/entry_tile.dart` | Vocabulary card: German headword over Persian meanings |
| `DeckTile` | `features/decks/presentation/deck_tile.dart` | Deck card with the box tile |

Buttons, fields, cards, dialogs, sheets, snackbars, chips, the segmented
control and navigation are styled once, in `AppTheme`. Screens use the
standard Material widgets, without wrappers.

## Direction rules

- The UI is Persian, RTL. German content is always LTR (`AutoDirectionText`
  for user content of unknown direction; explicit `TextDirection.ltr` for
  German fields and the scanned page).
- User content inserted into a Persian sentence (deck names, German words in
  confirmations and dialog titles) is wrapped with `bidiIsolate` (Unicode
  FSI…PDI). Without isolation, edge punctuation such as «Hallo!» is
  reordered.
- Spacing uses directional values, and the "forward" chevron flips with the
  layout.

## Accessibility and responsive rules

- Every tappable element is at least 48×48, including each word on a scanned
  page. The visible highlight hugs the word, while the tap area is the full
  48×48 box.
- Scanned-page words expose their text as the label, the button role, the
  selected state and a Persian hint ("select word" / "deselect word").
  Status changes (selection count, errors, results) are live regions.
- Text is never clamped; layouts reflow at 2× system text scale. Lists and
  dialogs scroll as a whole. On the selection screen, the instructions
  scroll with the page, so the text keeps its room on small screens.
- Dialog actions with long Persian labels are stacked, full-width and scroll
  with the content.
- Snackbars are fixed at the bottom, so a confirmation never covers a
  form's buttons.

Tests (`test/widgets/design_system_test.dart`):

- Every main screen at 320 px width, at 1.5× and 2× text, in light and dark:
  no overflow, with each list scrolled to the end.
- The duplicate dialog and the create-deck sheet at 320 px and 2×.
- The full OCR flow (select → review → save) at 320 px, at 1.5× and 2×.
- Scanned-page words: tap-target size, Android/iOS tap-target guidelines,
  semantics, labeled targets.
- Text-contrast guideline for selected words and the word detail, in both
  themes.
- Mixed-direction content: long compounds, umlauts/ß, several meanings,
  „“/«» quotes, Latin and Persian digits, multiline notes.

## Not verified

- No golden images. Widget tests render with Flutter's test font, not
  Vazirmatn/Literata, so they check layout robustness (the test font is wider
  than the real fonts) but not appearance.
- The design has not been viewed on a real iPhone or Android device, and no
  platform build has run on this machine. Real-device checks are still
  required:
  - Persian shaping and line height with Vazirmatn
  - Literata rendering
  - dark mode
  - system text scaling
  - VoiceOver/TalkBack reading of the scanned-page words
  - keyboard behavior in the word form and the create-deck sheet
