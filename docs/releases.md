# Releases

Every build that is given to the product owner (installed on a phone,
archived or uploaded) has a version, a build number and user-readable
release notes. The app shows all three for the build that is **installed**
in Settings → About AI WortBox (درباره برنامه).

## Where the information lives

| What | Source of truth | Shown where |
| --- | --- | --- |
| Version and build number | `version:` in `pubspec.yaml` (`1.0.0+3` = version 1.0.0, build 3). Flutter writes it into iOS `CFBundleShortVersionString`/`CFBundleVersion` and Android `versionName`/`versionCode`. | Settings → About, read at runtime from the installed app (`package_info_plus`), never hard-coded. |
| Release notes | `assets/release_notes.json` (bundled with the app) | Settings → About: the notes of exactly the installed build, plus earlier builds. A build without notes says so; notes of another build are never shown instead. |
| Release date | `date` in the same file (`YYYY-MM-DD`), or `null` when it is not known exactly | Settings → About, only when not `null`. |

`assets/release_notes.json`:

```json
{
  "formatVersion": 1,
  "releases": [
    {
      "version": "1.0.0",
      "build": 3,
      "date": "2026-10-20",
      "changes": {
        "fa": ["…", "…"],
        "en": ["…", "…"]
      }
    }
  ]
}
```

Each `changes` list describes what changed **compared with the previous
build**, in words a learner understands (no file names, commit ids or
internal terms). Persian and English have the same number of lines.

## Checklist for every release

1. Check that the new build number has never been used (`git log -p
   pubspec.yaml`, earlier archives/uploads). Build numbers only go up.
2. Raise `version:` in `pubspec.yaml`. Do not change the bundle identifier.
3. Add the build's entry at the top of `assets/release_notes.json` with
   Persian and English notes. Describe only what is implemented and
   verified; say plainly when something is partial or deferred. Set `date`
   only if it is accurate.
4. Run the checks. `test/features/about/release_notes_test.dart` fails if
   the pubspec version/build has no notes, if Persian or English notes are
   missing, or if the newest notes are not for the pubspec build.
5. Build, then read the build output and the built app's `Info.plist`
   (`CFBundleShortVersionString`, `CFBundleVersion`) — not only the exit
   code.
6. Before the product owner reviews or installs it, report the version,
   build number and the release notes. Never describe an update as
   installed, available or tested unless that actually happened.

## History

| Build | Version | Date | Notes |
| --- | --- | --- | --- |
| 4 | 1.0.0 | 2026-10-20 | Sentence-generation fix (unconfirmed live), card appearance |
| 3 | 1.0.0 | 2026-10-20 | Backup/restore, About screen, AI sentence practice |
| 2 | 1.0.0 | not recorded | Missing-meaning filter, AI meanings for selected words |
| 1 | 1.0.0 | not recorded | First build (Phases 1–5); no in-app notes |
