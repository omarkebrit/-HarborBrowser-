# Aster validation report

Validation is in progress as of 13 October 2026. The repository is public. [Run 38383638549](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38383638549), run number 12, attempt 1, is running for source `394e481cb5527591a54969859c1c353dd440082b`, native job `115249930684`. No completed full-validation result or production iPhone IPA is available yet.

The candidate changes only the popup-test visibility helper. It reads the label, viewport and window frames once each per predicate evaluation, requires finite positive label bounds contained in both the viewport and window, and uses the caller's 15/20-second timeout instead of a fixed five seconds. Production browser/media behavior is unchanged. The 180-minute workflow budget, early passing-regression checkpoint, attempt-specific artifacts and full test/IPA-publication gates remain intact.

## Completed evidence and current requirements

| Area | Latest completed evidence | Current full run |
| --- | --- | --- |
| Four media/session preflight cases | [Run 38377770464](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38377770464), source `d0a980ec3313bccb40bd31e4863bd9d5b92ac418`: 3 passed, 1 failed at the popup visibility wait | Must pass all four with zero failures or skips; early evidence checkpoint follows |
| Full upstream `UnitTest` plan | [Run 38083870485](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38083870485), source `51fe284ead04c0d17b55c51725aa590dd951d031`: passed | Pending; the later attempt 3 was canceled during unit compilation and added no unit-test result |
| Main local acceptance and selected upstream UI tests | Run 38083870485, source `51fe284ead04c0d17b55c51725aa590dd951d031`: 14 passed, 1 failed at the fullscreen post-rotation toolbar assertion | All 15 selected cases must pass; the strengthened fullscreen case passed the later preflight, but this full selection has not completed on that candidate |
| Native download and exact file-byte verification | No completed native download/integrity result | Dedicated download case and byte verification pending |
| Unsigned iPhone release build and packaging | Not completed; no IPA produced | Pending after all required native checks pass |
| Signed installation and physical-device validation | Not performed | Requires Apple signing and physical iPhone testing |

The earlier completed native test environment was Xcode 26.5 (17F42), iOS 26.5 (23F77), on an iPhone 15 Pro Max simulator using the standard `macos-26` runner. Results are bounded to their recorded sources and simulator environment.

## Popup assertion and current follow-up

Run 38377770464 passed restrictive autoplay followed by manual playback, fullscreen rotation/exit with actual menu → Settings → browser interaction, and 25-tab process restoration. The popup case found “Audio and video playing,” then its fixed five-second geometry wait timed out. No later unit, main UI, download or release stage completed in this run.

The failure screenshot shows decoded video and visible status, with 59 frames at 3.71 seconds. The final native hierarchy records 65 frames at 4.21 seconds, `paused: false`, `readyState: 4` and no media error. Its status bounds `(16, 381, 191, 24)` fit fully inside the native viewport `(0, 59, 430, 731)` and main window `(0, 0, 430, 932)`. Repeated native frame queries occurred during the short wait; the failing intermediate frame values were not recorded. The test-only polling change remains unverified until the active run completes.

Earlier run 38086721963 attempt 3, source `ae128811a91010fa972eba2849635d289e9b8e78`, passed all four cases. Initial native build/launch took 18 minutes 6 seconds and the cases took 669.133 seconds. That attempt was manually canceled during subsequent unit compilation, leaving no full-suite or IPA result.

## Evidence checkpoint

The current workflow checks the preflight summary for exactly four passes, zero failures and zero skips, exports attachments and uploads `Aster-regression-validation-evidence-attempt-1` before starting unit tests. This preserves completed regression proof if a later stage stops. The checkpoint is configured for the active run; no current-run checkpoint result is claimed yet.

Artifacts use an `attempt-N` suffix. The full native evidence is `Aster-native-validation-evidence-attempt-N`; filter evidence is `aster-ad-filters-attempt-N`. The future IPA artifact is `Aster-iPhone-UNSIGNED-needs-signing-attempt-N`, containing `Aster-UNSIGNED-needs-signing.ipa`. A checkpoint or filter artifact is not an installable app. An IPA is published only after all required native tests, download-integrity verification and the device build/package succeed. Artifact retention is seven days.

## Retained advertising snapshot

The checked-in pack is the exact snapshot tested and WebKit-compiled in run 38083870485: 40,723 rules, SHA-256 `3036112f5339915d24298fcbcd241f44b3a2f6b53e7ab4090ae2924f179f3ce3`. Its metadata, raw sources, converter revision and licenses are bundled in `firefox-ios/Client/Assets/AsterFilters/`. All recorded source/rule hashes were verified after downloading the artifact. The converter report records `errorsCount: 89` for unsupported source inputs and `discardedSafariRules: 0`; this is not a claim that every AdGuard rule is supported. Real WebKit compilation passed.

## Earlier local checks

Earlier local verification recorded 58 fixture-server HTTP contract checks covering HEAD, byte ranges, suffix ranges, invalid requests, missing resources and correct payloads. Fixture JavaScript syntax was checked with Node; the original six-second media fixture was confirmed as H.264 video with AAC audio, including HLS segments. Localization string syntax, opaque icon assets and primary palette text contrast were checked. New native source/resources and unit assertions were registered in the Xcode project.

These checks complement native execution. They do not replace the unexecuted download test, iPhone release compilation, signed installation or physical-device testing.

## Checks still required

- Complete the active workflow for its recorded source: four preflight cases, full upstream unit plan, all 15 main UI cases, dedicated download and exact file-byte verification.
- Complete the iPhone release build and packaging; verify any IPA against its recorded source commit.
- Provide valid Apple signing and matching provisioning for the app and all six extensions before installation. TestFlight also requires Apple Developer/App Store Connect setup; no signing credentials are configured.
- Test the signed application on a physical iPhone 15 Pro Max.

The existing [native gallery](docs/aster-screenshots/README.md) retains unmodified screenshots from run 38083870485, source `51fe284ead04c0d17b55c51725aa590dd951d031`. Its provenance remains unchanged; the newer passing menu/Settings interaction is evidenced by attempt 3's job log.

## Feature and validation limits

Aster is an independent native browser based on Firefox for iOS. It does not implement all Brave features or claim identical parity. Inherited blocking of known fingerprinter URLs is present, but Brave-style canvas/audio fingerprint randomization is not integrated. No dedicated cookie-banner filter or automatic consent-rejection feature is implemented. There is no user-facing strict HTTPS-only mode; inherited automatic HTTPS upgrades are feature-gated on iOS 18.2+ and permit HTTP fallback, with release-channel defaults off and developer/beta defaults on. Real HTTPS upgrade/fallback network behavior remains unverified.

Brave Playlist and a saved-media background-playback library, Brave Sync, Rewards, Wallet, Leo, News and paid VPN services are not implemented. Firefox Account integration remains inherited provider code whose independent identifiers, redirects and end-to-end use are unverified. The Apple-managed default-browser entitlement is not included. Advertising rules are refreshed during builds; this fork does not provide a background advertising-rule updater. Protection depends on the bundled lists and website behavior; no result promises removal of all advertising or tracking.

PiP and AirPlay are enabled in native WebKit configuration, with configuration-level unit assertions; actual PiP/device behavior and AirPlay receivers remain unverified. Simulator decoding of an AAC track is not evidence of audible sound on a physical iPhone. Signed credential extensions, Face ID, protected DRM streams, long-session battery/performance, background audio behavior, complete Arabic translations and accessibility on a physical device require further testing. The latest native run used an iPhone 15 Pro Max simulator and does not certify every supported iOS version. No finite test suite certifies all websites or every browser feature.
