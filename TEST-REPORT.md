# Aster validation report

Validation is in progress as of 13 October 2026. The repository is public. [Run 38393771825](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38393771825), run number 15, attempt 1, has passed all four native preflight cases for source `aab3dc3ac23bf2e58c1334920fe70528e9dad527`. Its strict summary and early evidence artifact are preserved. The full unit plan is running; main UI, download and device-release results remain pending. No completed full-validation result or production iPhone IPA is available yet.

The checkpoint verifies the acceptance-test new-tab helper's tray route: 24 genuine tray creation taps, exact per-page counts, 25 unique numbered pages, process relaunch and actual first-tab tray selection. Both saved window archives retain all 25 unique fixture URLs; pages 25 and 1 were reopened after relaunch, rather than every restored page. The alternative context-menu command route was not invoked; it remains code-reviewed without runtime verification from this preflight. Production browser/media and gesture thresholds are unchanged. The 180-minute workflow budget and strict four-preflight/15-main/one-download gates, plus the full unit plan, remain required before IPA publication.

## Completed evidence and current requirements

| Area | Latest completed evidence | Current full run |
| --- | --- | --- |
| Four media/session preflight cases | Run 38393771825, source `aab3dc3ac23bf2e58c1334920fe70528e9dad527`: official summary records 4 passed, 0 failed, 0 skipped | Passed; strict summary and early evidence artifact saved |
| Full upstream `UnitTest` plan | [Run 38083870485](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38083870485), source `51fe284ead04c0d17b55c51725aa590dd951d031`: passed | Running for the current source; its completed result remains pending |
| Main local acceptance and selected upstream UI tests | Run 38083870485, source `51fe284ead04c0d17b55c51725aa590dd951d031`: 14 passed, 1 failed at the fullscreen post-rotation toolbar assertion | Pending; all 15 selected cases must pass for the current source |
| Native download and exact file-byte verification | No completed native download/integrity result | Dedicated download case and byte verification pending |
| Unsigned iPhone release build and packaging | Not completed; no IPA produced | Pending after all required native checks pass |
| Signed installation and physical-device validation | Not performed | Requires Apple signing and physical iPhone testing |

The earlier completed native test environment was Xcode 26.5 (17F42), iOS 26.5 (23F77), on an iPhone 15 Pro Max simulator using the standard `macos-26` runner. Results are bounded to their recorded sources and simulator environment.

## Verified preflight checkpoint

The official `AsterRegressionTests-summary.json` records `result: Passed`, four passes, zero failures and zero skips. Its recorded source matches `aab3dc3ac23bf2e58c1334920fe70528e9dad527`. The environment is Xcode 26.5 (17F42), iOS 26.5 (23F77), on the iPhone 15 Pro Max simulator. The checkpoint includes popup playback, restrictive autoplay, fullscreen exit with real menu/Settings interaction, and completed 25-tab creation/restoration.

The preceding run 38386794212 failed while requesting tab 4 because a tabs context menu appeared where the test expected the tray. The gesture-recognition cause remains unknown. The current passing creation case used the regular tray throughout, so it does not establish why that earlier menu appeared or verify the alternative command branch or the current helper's private-mode creation route.

Earlier run 38086721963 attempt 3, source `ae128811a91010fa972eba2849635d289e9b8e78`, passed all four cases. Initial native build/launch took 18 minutes 6 seconds and the cases took 669.133 seconds. That attempt was manually canceled during subsequent unit compilation, leaving no full-suite or IPA result.

## Evidence checkpoint

The strict four-pass/zero-failure/zero-skip summary check and upload completed successfully. `Aster-regression-validation-evidence-attempt-1` preserves the result bundle, summary, attachments, logs and recorded source before the remaining tests. This completed checkpoint remains available if a later stage stops; it is a partial validation result.

Artifacts use an `attempt-N` suffix. The full native evidence is `Aster-native-validation-evidence-attempt-N`; filter evidence is `aster-ad-filters-attempt-N`. The future IPA artifact is `Aster-iPhone-UNSIGNED-needs-signing-attempt-N`, containing `Aster-UNSIGNED-needs-signing.ipa`. A checkpoint or filter artifact is not an installable app. An IPA is published only after all required native tests, download-integrity verification and the device build/package succeed. Artifact retention is seven days.

## Retained advertising snapshot

The checked-in pack is the exact snapshot tested and WebKit-compiled in run 38083870485: 40,723 rules, SHA-256 `3036112f5339915d24298fcbcd241f44b3a2f6b53e7ab4090ae2924f179f3ce3`. Its metadata, raw sources, converter revision and licenses are bundled in `firefox-ios/Client/Assets/AsterFilters/`. All recorded source/rule hashes were verified after downloading the artifact. The converter report records `errorsCount: 89` for unsupported source inputs and `discardedSafariRules: 0`; this is not a claim that every AdGuard rule is supported. Real WebKit compilation passed.

## Earlier local checks

Earlier local verification recorded 58 fixture-server HTTP contract checks covering HEAD, byte ranges, suffix ranges, invalid requests, missing resources and correct payloads. Fixture JavaScript syntax was checked with Node; the original six-second media fixture was confirmed as H.264 video with AAC audio, including HLS segments. Localization string syntax, opaque icon assets and primary palette text contrast were checked. New native source/resources and unit assertions were registered in the Xcode project.

These checks complement native execution. They do not replace the unexecuted download test, iPhone release compilation, signed installation or physical-device testing.

## Checks still required

- Complete the remaining checks for the recorded source: full upstream unit plan, all 15 main UI cases, dedicated download and exact file-byte verification. The four preflight cases have passed.
- Complete the iPhone release build and packaging; verify any IPA against its recorded source commit.
- Provide valid Apple signing and matching provisioning for the app and all six extensions before installation. TestFlight also requires Apple Developer/App Store Connect setup; no signing credentials are configured.
- Test the signed application on a physical iPhone 15 Pro Max.

The existing [native gallery](docs/aster-screenshots/README.md) retains unmodified screenshots from run 38083870485, source `51fe284ead04c0d17b55c51725aa590dd951d031`. Its provenance remains unchanged; the newer passing menu/Settings interaction is evidenced by attempt 3's job log.

## Feature and validation limits

Aster is an independent native browser based on Firefox for iOS. It does not implement all Brave features or claim identical parity. Inherited blocking of known fingerprinter URLs is present, but Brave-style canvas/audio fingerprint randomization is not integrated. No dedicated cookie-banner filter or automatic consent-rejection feature is implemented. There is no user-facing strict HTTPS-only mode; inherited automatic HTTPS upgrades are feature-gated on iOS 18.2+ and permit HTTP fallback, with release-channel defaults off and developer/beta defaults on. Real HTTPS upgrade/fallback network behavior remains unverified.

Brave Playlist and a saved-media background-playback library, Brave Sync, Rewards, Wallet, Leo, News and paid VPN services are not implemented. Firefox Account integration remains inherited provider code whose independent identifiers, redirects and end-to-end use are unverified. The Apple-managed default-browser entitlement is not included. Advertising rules are refreshed during builds; this fork does not provide a background advertising-rule updater. Protection depends on the bundled lists and website behavior; no result promises removal of all advertising or tracking.

PiP and AirPlay are enabled in native WebKit configuration, with configuration-level unit assertions; actual PiP/device behavior and AirPlay receivers remain unverified. Simulator decoding of an AAC track is not evidence of audible sound on a physical iPhone. Signed credential extensions, Face ID, protected DRM streams, long-session battery/performance, background audio behavior, complete Arabic translations and accessibility on a physical device require further testing. The latest native run used an iPhone 15 Pro Max simulator and does not certify every supported iOS version. No finite test suite certifies all websites or every browser feature.
