# Bible Companion — product polish working copy

This is a separate editable copy. The source ZIP, original Desktop project, and synced project references were not changed.

## Open and run

1. Open `BibleCompanion Swift.xcodeproj` in this folder, using Xcode 27.
2. Select the **BibleCompanion Swift** scheme and your iPhone or an iPhone simulator.
3. Keep the original signing team and bundle identifiers, or select your own team if Xcode requests it.
4. Run the app. If updating the existing installation, keep it installed to preserve its local data. A fresh simulator can be used for onboarding checks.
5. Open **You → Reading & appearance** for palettes, dark/light appearance, Scripture typography, Companion motion, and Today section controls.

The configured service remains `https://example.invalid`. A hosted HTTPS request does not need local-network permission. The old conversation's localhost/IP instructions describe an earlier configuration.

## Included changes

- Today, Bible, Companion, Journey, and You tabs, with separate navigation stacks.
- A short optional personalization setup and a prepared-space introduction. The longer questionnaire remains available.
- Clearer welcome copy, scrollable onboarding, immediate name-field focus, and keyboard dismissal.
- Sky, Baby Pink, Parchment, Sage, Rose, and Lavender palettes. Baby Pink uses a soft pink cloud backdrop with readable berry accents, and is selectable during quick setup or in appearance settings. Semantic surfaces and text adapt to light/dark appearance on iOS.
- Scripture typeface, size, and line-spacing controls retained; optional Today growth and saved-Scripture sections added.
- Companion animations respect both the in-app choice and the device's Reduced Motion setting.
- An opaque 1024×1024 app icon based on the supplied Companion artwork.
- Bible decoding coalesced and cached, with asynchronous loading. Explorer indexing and keyword filtering run off the main actor; canceled/outdated searches cannot replace newer results.
- Companion typing isolated from the message list. Daily reflection editing uses a local draft, debounced saves, and immediate saves on leaving/backgrounding/completion.
- Today no longer waits for automatic AI recommendation generation. Existing saved recommendations and paths still load.
- Uniform bounded network requests and friendly offline, timeout, busy, and server-failure messages. POSTs are not automatically retried.
- Failed regular Companion requests show a separate retry notice rather than a fabricated chat reply. Retry preserves the original visible message.
- Bible loading indicators and an always-visible search control.
- Swift actor-isolation warnings corrected. The widget's minimum iOS version matches the app's iOS 17 minimum.
- Broad insecure transport permission removed; the existing local-development exception remains.

Existing profile, Library, chat, reflection, journey, and growth storage keys remain in use. Existing v1 app settings migrate with defaults for the new fields. Unreadable settings are preserved until an explicit reset.

## Verification

`Validation/FoundationChecks.swift` checks old-setting migration, new-setting persistence, invalid-data preservation, the actual bundled Bible, reference parsing, and mocked networking failures. No paid AI requests are made by these checks.

Run `Validation/run-foundation-checks.sh` from Terminal with Xcode installed.

Simulator launch screenshots are under `Validation/Screenshots`. These are launch-state checks, not a claim that every interaction or a physical phone was tested. Interactive tap-through checks could not be completed reliably because the Device Hub selection changed during control attempts. The full interaction pass remains outstanding.

The debug-only `BIBLECOMPANION_OFFLINE_PREVIEW=1` flag prevents all Companion network requests during offline previews.

The debug-only `BIBLECOMPANION_PREVIEW_SETTINGS` environment variable accepts a settings JSON object for isolated screenshot previews. It does not persist the supplied values on launch and is omitted from Release builds.

## Work still requiring verification

- Physical iPhone input latency and real AI generation against the deployed service.
- Full tap-through QA: longer onboarding, path changes, study generation, reflection restoration, bookmarking/highlighting/notes, widget installation/deep links, and accessibility sizes.
- Hosted backend health, credentials, deployment settings, and operational protections such as authentication/rate limits.
- The full set of app screens in every palette; personalization currently supports curated palettes and section visibility rather than unrestricted layout editing.
- App Store distribution/signing and Release archive validation.

`Backend/server.py` and `Backend/requirements.txt` are unchanged reference copies of the discovered Desktop backend. No environment files, keys, virtual environment, or deployment credentials are included. This package is an implementation for review and testing, not an asserted production-ready release.
