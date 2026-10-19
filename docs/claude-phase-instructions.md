# Phase Working Instructions

Rules for whoever implements AI WortBox (including Claude Code), phase by
phase. They complement the product specification and
[implementation-plan.md](implementation-plan.md).

## Approval gates

1. Work only on the phase that is currently approved. Current state:
   **Phase 5** (scope selected by the product owner; see the roadmap) is
   implemented, together with the product owner's follow-up request
   (D42–D47: FSRS review, review direction, hidden answers, photo word
   selection, iOS speech fix, bulk delete). No later phase exists; other
   proposals are not approved.
2. At the end of each phase: report and **stop**. Do not start the next phase
   without explicit approval.
3. Items in the proposed-feature register (P1–P13, Anki `.apkg`) are
   **not approved**. Do not implement them, add dependencies for them or
   change the schema for them, even if they look small or adjacent to the
   current phase. If an approved task seems to need one, stop and ask.
4. Documentation-only requests change documentation only: no source, schema,
   dependency, test or runtime changes, and no commit unless asked.

## Git

- One commit per phase, with the message the product owner specifies.
- Before committing: inspect `git status` and the full diff; make sure no
  secrets, local machine configuration, build outputs or temporary files are
  included; check `.gitignore`.
- Never rewrite history, force-push, reset, or discard uncommitted work.
- Keep unrelated changes (e.g. documentation-only updates) out of a phase
  commit unless the product owner says to include them.

## Before coding a phase

- Inspect existing models, schema, repositories, navigation and tests;
  extend the architecture instead of duplicating it.
- Verify every new dependency (maintenance, platform support, SDK
  compatibility) before adding it, and record why in `docs/decisions.md`.
- Schema changes follow the migration policy in the roadmap: only for
  approved features, documented first, migration tests from real older data.

## During a phase

- Keep scheduling, OCR, CSV parsing and AI enrichment independent of widgets.
- Preserve the original German spelling; never merge distinct meanings
  without an explicit user choice; never reset review state when content is
  edited.
- Keep everything offline-capable except AI features.
- Never put API keys in the app, committed configuration or logs; use mocks
  in automated tests.

## End-of-phase report

1. Summary of completed functionality.
2. Files created or changed.
3. Database changes and migrations.
4. Dependencies added and why.
5. Commands executed and their actual results (format, analyze, tests,
   builds).
6. Known issues and limitations.
7. Manual verification checklist.
8. Scope of the next phase.

Never claim a test or build passed unless it actually ran and passed. iOS and
Android builds are currently **unverified** (no Android SDK, no full Xcode)
and must be reported that way until real builds run.

## Phase-specific reminders

- **Phase 3:** never save every recognized word; do not upload page images;
  explain that OCR can be wrong; provide a typed-text fallback; verify ML Kit
  German support on both platforms before relying on it.
- **Phase 4:** provider-neutral enrichment interface; bring your own key
  (D27/D28): each user's OpenRouter key lives only in OS secure storage and
  the app calls OpenRouter directly over HTTPS — there is no backend or proxy
  (a backend is a possible future alternative, not current scope); no request
  without a saved key and an explicit user action; never claim real AI works
  when only mocks ran; protect user-edited content.
- **Phase 5 (as implemented):** practice and statistics come only from
  explicitly recorded answers; scheduled review uses the `fsrs` package
  (D42) and free practice is never presented as FSRS; inject a clock; do
  not claim words are permanently learned; never claim Anki, TTS, OCR
  alignment or notification behaviour that was not verified (see
  `docs/testing.md`).
