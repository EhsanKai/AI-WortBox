# Installing AI WortBox on an iPhone

This guide is for developers and testers who want to run AI WortBox on a
real iPhone. There are two routes:

| Route | Who it is for | Apple account | App keeps working |
| --- | --- | --- | --- |
| [A. Build it yourself](#a-install-on-your-own-iphone-development-build) | A developer with a Mac | Free Apple ID is enough | 7 days (free account) or 1 year (paid), then re-install |
| [B. TestFlight](#b-install-through-testflight) | Anyone invited by the account owner | Paid Apple Developer Program (owner only) | 90 days per build |

Sections [C](#c-ai-meanings-with-your-own-openrouter-key-byok) and
[D](#d-troubleshooting-and-release-workflow) explain the optional AI key and
common problems.

Facts about this project that the steps below rely on:

- Bundle identifier: `com.aiwortbox.aiWortbox`
- Minimum iOS version: 15.5 (`ios/Podfile`, Xcode project)
- Version: `version:` in `pubspec.yaml` (`1.0.0+3` means version 1.0.0,
  build 3). Every new build needs a higher build number and release notes
  ([releases](releases.md)). The installed version, build and its changes
  are shown in the app under Settings → About AI WortBox (درباره برنامه).
- All data (words, reviews, settings) lives in a local SQLite database on the
  phone. There is no account and no server.

---

## A. Install on your own iPhone (development build)

### A1. Prerequisites

- A Mac with the current **Xcode** from the App Store. Open it once and let
  it install its components.
- **Flutter** 3.47 stable or newer (`flutter --version`). Run `flutter
  doctor` and fix what it reports for iOS.
- **CocoaPods** (`pod --version`). If CocoaPods warns about UTF-8, run
  `export LANG=en_US.UTF-8` first.
- An **Apple ID** added in Xcode → Settings → Accounts. A free Apple ID
  creates a "Personal Team"; a paid Apple Developer Program membership
  creates a regular team.
- A USB cable for the first connection.

### A2. Prepare the iPhone

1. Connect the iPhone by USB and unlock it. Tap **Trust** on the phone
   and enter the passcode.
2. In Xcode → Window → Devices and Simulators, wait until the phone shows
   as connected (the first time, Xcode copies debug symbols; this can take
   several minutes). Optionally tick **Connect via network** for wireless
   installs later.
3. Turn on **Developer Mode** (iOS 16 and later): Settings → Privacy &
   Security → Developer Mode → On, then restart the phone and confirm. The
   option appears only after the phone has been connected to Xcode once.

### A3. Get the code and dependencies

```sh
git clone https://github.com/EhsanKai/AI-WortBox.git
cd AI-WortBox
flutter pub get
cd ios && pod install && cd ..
```

Generated code (Drift tables, localizations) is committed, so no code
generation is needed for a build.

### A4. Signing

1. Open **`ios/Runner.xcworkspace`** (the workspace, not the
   `.xcodeproj`).
2. Select the **Runner** target → **Signing & Capabilities**.
3. Keep **Automatically manage signing** on and choose your **Team**.
4. If Xcode says the bundle identifier is not available (it is registered
   to another team), change it to something unique, e.g.
   `com.<yourname>.aiwortbox`, for all three build configurations. Do not
   commit that change if you are not the project owner.

The project's committed team id belongs to the project owner's account;
choosing your own team in Xcode changes `ios/Runner.xcodeproj/project.pbxproj`
locally. Keep such changes out of pull requests.

### A5. Build and install

Check that Flutter sees the phone:

```sh
flutter devices
```

Then either run it from Flutter (installs and starts the app; release mode
is fast and does not need a running debug session afterwards):

```sh
flutter run --release -d <device-id>
```

or build first and install the built app with Apple's `devicectl`:

```sh
flutter build ios --release
xcrun devicectl list devices
xcrun devicectl device install app --device <devicectl-identifier> build/ios/iphoneos/Runner.app
```

Use the `.app` path that `flutter build ios` prints in its last line ("Built
…"). Over Wi-Fi the first install attempt sometimes fails with "Connection
reset by peer"; simply run the same command again.

With a **free** Apple ID, the first launch is blocked until you trust the
developer: Settings → General → VPN & Device Management → your Apple ID →
**Trust**.

### A6. Updating without losing data

Installing a new build **over** the existing app (same bundle identifier,
same team) keeps all words, review history and settings. Do **not** delete
the app from the phone first: deleting it deletes its database.

Before risky changes (a different team or bundle identifier, a new phone),
save a full backup: Settings → Backup and restore → Save backup file. It
contains all decks, words, tags, the review schedule (FSRS) and review
history, but not settings or the API key (enter the key again after a
restore). Restore it on the new installation from the same screen. CSV and
Anki exports are not backups (no review state).

### A7. Limits of development signing

- **Free Apple ID (Personal Team):** the provisioning profile expires after
  **7 days**. The app then no longer opens until you build and install it
  again (A5); data is kept when you install over it. At most 3 apps from a
  free account can be on a device at a time, and the app cannot be
  distributed to others.
- **Paid membership:** development profiles last one year. For other
  people, use TestFlight (B).

---

## B. Install through TestFlight

TestFlight is Apple's beta distribution. Testers install the official
**TestFlight** app from the App Store and get AI WortBox from there, without
a Mac or a cable.

### B1. What is automated here and what only the account owner can do

| Step | Who |
| --- | --- |
| Version/build number in `pubspec.yaml`, release build, archive | Anyone with the code (`flutter build ipa`) |
| Apple Developer Program membership (paid, yearly) | **Account owner** |
| Accept agreements in App Store Connect → Business | **Account owner** |
| Register the bundle id, create the app record in App Store Connect | **Account owner** (or an Admin/App Manager) |
| Distribution certificate and App Store provisioning profile | Xcode creates them automatically once the team is a paid team |
| Upload, export-compliance answer, tester groups, invitations | **Account owner** (or an Admin/App Manager) |
| External testing (beta app review) | **Account owner**; Apple reviews |

**Current state of this project (2026-10-20):** the Apple account used so far
is a free Personal Team. A release archive (`1.0.0`, build `2`) builds and
was checked locally (build `3` was built with `flutter build ios --release`
for the development-signed install, not archived), but exporting an App Store IPA fails with "Team … does
not have permission to create 'iOS App Store' provisioning profiles". **No
build has been uploaded to App Store Connect and nothing is in TestFlight.**
The steps below are what remains.

### B2. One-time setup (account owner)

1. **Enroll** in the Apple Developer Program at
   <https://developer.apple.com/programs/enroll/> (individual or
   organization). Wait until the membership is active.
2. In **App Store Connect** (<https://appstoreconnect.apple.com>) →
   Business, accept the current agreements. Paid-app tax and banking
   details are not needed for a free TestFlight beta.
3. In Xcode → Settings → Accounts, sign in with the enrolled Apple ID and
   check that the paid team (not "Personal Team") is listed.
4. Open `ios/Runner.xcworkspace` → Runner → Signing & Capabilities and
   select the **paid team**. Xcode registers `com.aiwortbox.aiWortbox` for
   that team. If the identifier is reported as unavailable (it is still
   held by the old Personal Team), choose a new one; installing an app
   with a different identifier creates a separate app with an empty
   database, so export your decks first (A6).
5. In App Store Connect → Apps → **+** → New App: platform iOS, name
   "AI WortBox" (must be unique on the App Store; pick another if taken),
   primary language, the bundle id from step 4, any SKU (e.g.
   `aiwortbox`).

### B3. Build, archive and upload

1. Raise the build number in `pubspec.yaml` (e.g. `1.0.0+3` → `1.0.0+4`)
   and add release notes for it ([releases](releases.md)) for every upload. The version (`1.0.0`) may stay the same within one
   beta.
2. Build the archive and IPA:

   ```sh
   flutter build ipa --release
   ```

   This writes `build/ios/archive/Runner.xcarchive` and, with a paid team,
   `build/ios/ipa/*.ipa`. **Check the output for "Encountered error while
   creating the IPA"**: `flutter build ipa` can exit successfully even when
   only the archive was created.
3. Upload, using one of Apple's tools:
   - **Xcode:** `open build/ios/archive/Runner.xcarchive` → Organizer →
     **Distribute App** → **App Store Connect** → Upload. Xcode validates
     the archive and signs it with the distribution certificate.
   - **Transporter** (Mac App Store): drag in the `.ipa` and deliver it.
   - **Command line** with an App Store Connect API key (created by the
     owner under Users and Access → Integrations; the `.p8` file stays in
     `~/.appstoreconnect/private_keys/`, never in the repository):

     ```sh
     xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \
       --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
     ```

4. Within minutes to about an hour the build appears in App Store Connect →
   your app → **TestFlight** with the status "Processing", then "Ready to
   Submit"/"Ready to Test". Apple e-mails if processing finds a problem.
5. **Export compliance:** App Store Connect asks for each build whether
   the app uses encryption. AI WortBox only uses standard HTTPS (to
   OpenRouter). The answer is a legal declaration by the account owner; it
   is not pre-filled in `Info.plist` in this repository.

### B4. Testers

- **Internal testing** (up to 100 people who are users of the App Store
  Connect team): TestFlight → Internal Testing → create a group → add
  testers → add the build. No Apple review is needed; testers get an
  e-mail invitation as soon as the build is processed.
- **External testing** (up to 10,000 people with any Apple ID): create an
  external group, fill in Test Information (description, feedback e-mail,
  privacy policy URL if requested), add the build and **submit it for Beta
  App Review**. The first build of each version is reviewed by Apple
  (usually within a day or two). Afterwards, invite testers by e-mail or
  enable a **public link** generated by App Store Connect.
- Only use invitation links and QR codes generated by App Store Connect.

### B5. Installing as a tester

1. On the iPhone, install **TestFlight** from the App Store.
2. Open the invitation e-mail on the iPhone and tap **View in TestFlight**,
   or open the public link from App Store Connect, or enter the redeem code.
3. In TestFlight, tap **Install** (or **Accept**, then Install).
4. New builds appear in TestFlight; tap **Update** (or turn on automatic
   updates for the app in TestFlight). Updating keeps the app's data.

Limits:

- Each build expires **90 days** after upload; afterwards it no longer
  opens until you install a newer build.
- A TestFlight build replaces a development build only if both use the
  same bundle identifier. Keychain items (the OpenRouter key) are tied to
  the team; after changing teams, enter the key again.
- iOS 15.5 or later is required.

### B6. Before submitting to the App Store (not needed for TestFlight)

The app icon is still Flutter's default placeholder
(`ios/Runner/Assets.xcassets/AppIcon.appiconset`). It is valid for upload but
should be replaced before external testing or App Store review. The project
also allows iPad (`TARGETED_DEVICE_FAMILY = "1,2"`), so an App Store
submission would need iPad screenshots.

---

## C. AI meanings with your own OpenRouter key (BYOK)

AI suggestions are optional. Everything else works without a key or an
internet connection.

- Each user enters **their own OpenRouter API key** in the app (Settings →
  AI). Keys are created at <https://openrouter.ai/keys>. The repository and
  this documentation contain no key, and no key is built into the app.
- The key is stored only in the iOS **Keychain** (accessible while the
  device is unlocked, never synced to iCloud or restored to another device)
  or, on Android, in Keystore-protected storage. It is never written to the
  database, exports, logs or error messages.
- The app calls OpenRouter directly over HTTPS; there is no backend.
- **Free models only** is on by default: requests go only to free models
  and carry a zero price limit, so OpenRouter refuses paid routing. Turning
  it off uses the chosen paid model and bills the user's OpenRouter
  account.
- What is sent: for each word, only the German word, the sentence it came
  from (if any) and its existing meanings. For "AI meanings for selected"
  (see below) only the selected words **without** a meaning are sent, and
  only Persian meanings are requested.
- Nothing is saved until you review the suggestions; you can edit, accept
  or reject each one.

**Filling in missing meanings in bulk:** My Words → search (or a deck) →
**Missing meaning** filter → long-press a word → select all or tap words →
✨ **AI meanings for selected** → Get suggestions → review → Save. Words are
sent several at a time (5 per request by default, adjustable 1–10 under
Settings → AI), so 10 words normally take 2 requests instead of 10. Fewer
requests mean fewer round trips and less pressure on free-tier request
limits; the token cost (on paid models) still depends on how much text is
sent and returned, so the saving is not a fixed percentage.

---

## D. Troubleshooting and release workflow

### Everyday commands

```sh
flutter pub get                       # dependencies (+ localizations)
cd ios && pod install && cd ..        # iOS native dependencies
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build ios --release           # development-signed .app for your phone
flutter build ipa --release           # archive (+ IPA with a paid team)
```

After changing ARB files: `flutter gen-l10n`. After changing database
tables: `dart run build_runner build`.

### Release checklist

1. Raise the build number in `pubspec.yaml` and add the build's Persian and
   English notes to `assets/release_notes.json` ([releases](releases.md)).
2. Run format, analyze and tests (all must pass; the release-notes test
   fails without notes for the new build).
3. `flutter build ipa --release`; read the output for IPA export errors.
4. Upload (B3), wait for processing, answer export compliance.
5. Add the build to the tester groups (B4).

### Common problems

| Problem | Fix |
| --- | --- |
| `flutter devices` does not list the phone | Unlock it, reconnect by USB, tap Trust, open Xcode → Devices and Simulators and wait for "preparing" to finish; check Developer Mode is on. |
| "Developer Mode disabled" / app will not install | Settings → Privacy & Security → Developer Mode → On, restart. |
| "Untrusted Developer" on launch | Settings → General → VPN & Device Management → Trust (free accounts). |
| App stops opening after a week | Free-account profile expired (A7): build and install again. |
| "No profiles for 'com.aiwortbox.aiWortbox' were found" / "Failed to register bundle identifier" | Select your team in Signing & Capabilities; if the identifier is taken, use your own (A4). |
| "No signing certificate 'iOS Distribution' found" / "does not have permission to create 'iOS App Store' provisioning profiles" | The team is a free Personal Team; TestFlight needs a paid membership (B2). |
| `pod install` errors or "Podfile.lock out of sync" | `cd ios && pod repo update && pod install`; make sure `export LANG=en_US.UTF-8` is set. |
| Build fails after a Flutter upgrade | `flutter clean && flutter pub get && cd ios && pod install`. |
| `devicectl` install fails with "Connection reset by peer" (Wi-Fi) | Run the same command again, or use USB. |
| Upload rejected: build number already used | Raise the number after `+` in `pubspec.yaml` and rebuild. |
| AI: "not set up" | Enter your OpenRouter key under Settings → AI. |
