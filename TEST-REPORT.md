# Aster validation report

Validation is in progress as of 20 October 2026. The repository is public. [Run 17](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38410673448), source `6d8eec264d4eaafea4eaed6bd2ff919e0005f7f8`, completed with an official preflight summary of three passes, one failure and zero skips. Popup playback, restrictive autoplay and 25-tab creation/restoration passed; fullscreen video froze after rotation at its first loop boundary. The remaining native stages were gated. No completed full-validation result or production iPhone IPA is available yet.

The next candidate adds read-only playback/ownership diagnostics and requires fresh decoded frames through two landscape loops. Native [run 18](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39379658275), attempt 1, is launched for source `7788245534fc23c00a93fb8375c83ebce8703a1e`; its results remain unverified, and these changes do not establish a fix. CI now runs the full unit plan first and independently executes the preflight, main UI, download and device-build/package-audit stages even if another stage fails. IPA publication still requires all required checks to pass.

## Completed evidence and current requirements

| Area | Latest completed evidence | Current requirement |
| --- | --- | --- |
| Four media/session preflight cases | Run 17: official 3 passed, 1 failed, 0 skipped; fullscreen video stalled after rotation | All four must pass, including the stronger decoded-frame/two-loop assertion |
| Full upstream `UnitTest` plan | Run 15 failed `SearchTests.testSuggestClient` at its first 10-second expectation; no aggregate official count is claimed. Earlier [run 38083870485](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38083870485), source `51fe284ead04c0d17b55c51725aa590dd951d031`, passed | Async fixture fix and full plan require native verification; runs 16 and 17 did not reach units |
| Main local acceptance and selected upstream UI tests | Run 38083870485: 14 passed, 1 failed at the fullscreen post-rotation toolbar assertion | All 15 selected cases must pass for the candidate source |
| Native download and exact file-byte verification | No completed native download/integrity result | Dedicated download case and byte verification pending |
| Unsigned iPhone release build and actual IPA audit | No device IPA produced or audited | Device compilation, package integrity and all publication gates must pass |
| Signed installation and physical-device validation | Not performed | Requires Apple signing and physical iPhone testing |

The earlier completed native test environment was Xcode 26.5 (17F42), iOS 26.5 (23F77), on an iPhone 15 Pro Max simulator using the standard `macos-26` runner. Results are bounded to their recorded sources and simulator environment.

## Verified preflight checkpoint

[Run 15](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38393771825)'s official `AsterRegressionTests-summary.json` records `result: Passed`, four passes, zero failures and zero skips. Its recorded source matches `aab3dc3ac23bf2e58c1334920fe70528e9dad527`. The environment is Xcode 26.5 (17F42), iOS 26.5 (23F77), on the iPhone 15 Pro Max simulator. The checkpoint includes popup playback, restrictive autoplay, fullscreen exit with real menu/Settings interaction, and completed 25-tab creation/restoration.

The preceding run 38386794212 failed while requesting tab 4 because a tabs context menu appeared where the test expected the tray. The gesture-recognition cause remains unknown. Run 15's passing creation case used the regular tray throughout, so it does not establish why that earlier menu appeared or verify the alternative command branch or the helper's private-mode creation route.

Earlier run 38086721963 attempt 3, source `ae128811a91010fa972eba2849635d289e9b8e78`, passed all four cases. Initial native build/launch took 18 minutes 6 seconds and the cases took 669.133 seconds. That attempt was manually canceled during subsequent unit compilation, leaving no full-suite or IPA result.

## Latest fullscreen failure and diagnostic candidate

Run 17's popup and restrictive-autoplay cases passed in 114.987 and 74.272 seconds; the 25-tab case passed in 686.101 seconds. The fullscreen case failed after 54.709 seconds at `Missing rendered media text: Fullscreen video playing in landscape`. The official summary records three passes, one failure, zero skips and zero expected failures.

The native recording shows decoded portrait frames near media time 5.167 seconds. After rotation around the six-second loop boundary, the landscape stage is correctly sized but the video remains at time 0.000/frame 0 for about 15 seconds. The old page status retains its previous portrait-playing text; the failure is supported by frozen video frames and the native media time, rather than that stale label alone. The cause remains unconfirmed. The MP4 decodes cleanly across repeated loops with FFmpeg, and local byte-range checks have not identified a fixture-server defect.

The candidate records media time, paused/ended flags, readiness/network state, errors, decoded frames and recent media events. DEBUG-only native probes record WebView fullscreen transitions, ownership, geometry and public playback state. These observations do not start, pause, seek or resume media. The acceptance case also requires two landscape loops with newly decoded frames before exiting fullscreen and interacting with the native menu and Settings. Native compilation and execution results for this candidate remain unverified.

## Verified document-readiness change

Run 16 failed its 10-second existence wait for `Local tab 7 ready`, before any hittability assertion. Its fixture request arrived about 23 seconds after Return; final evidence showed the correct document and native count 7. No production cache or timer defect was verified.

Run 17 gave only the 25-tab stress case a 30-second document-existence budget and passed it. Other existence defaults and the subsequent 10/20-second hittability budgets were unchanged. All 25 numbered loads, exact counts, process relaunch and first-tab tray selection remained required. This proves that scoped readiness change for run 17's source, without establishing the owner of run 16's delay.

## Current unit-fixture fix

Run 15's job log records `SearchTests.testSuggestClient` timing out while waiting for its first local suggestion response. The server served successful responses after that deadline; server deallocation is not established as the cause. The fix introduced in run 16 and retained in run 17 makes this main-actor test async so it yields while the production URL session delivers callbacks on the main queue. It retains the server through both queries and stops it afterward. Both 10-second deadlines, real localhost requests, six exact suggestion assertions and error checks are unchanged. No production browser code changed. Runtime verification remains pending because runs 16 and 17's preflight failures gated unit execution.

The candidate runs units first so this fix can be checked before the media preflight. Independent subsequent stages collect additional native results despite earlier failures. Official summaries are exported for every result bundle present. The actual device package is audited even when an earlier test fails; failed runs preserve audit JSON/logs, while IPA bytes are published only after all required checks pass.

## Evidence checkpoint

Run 15's strict four-pass/zero-failure/zero-skip summary check and upload completed successfully. Its `Aster-regression-validation-evidence-attempt-1` preserves the result bundle, summary, attachments, logs and recorded source before the remaining tests. This completed checkpoint remains available despite the later unit failure; it is a partial validation result for the recorded source.

Artifacts use an `attempt-N` suffix. The full native evidence is `Aster-native-validation-evidence-attempt-N`; filter evidence is `aster-ad-filters-attempt-N`. The future IPA artifact is `Aster-iPhone-UNSIGNED-needs-signing-attempt-N`, containing `Aster-UNSIGNED-needs-signing.ipa`. A checkpoint or filter artifact is not an installable app. An IPA is published only after all required native tests, download-integrity verification, device build/package and actual-package audit succeed. Artifact retention is seven days.

## Retained advertising snapshot

The checked-in pack is the exact snapshot tested and WebKit-compiled in run 38083870485: 40,723 rules, SHA-256 `3036112f5339915d24298fcbcd241f44b3a2f6b53e7ab4090ae2924f179f3ce3`. Its metadata, raw sources, converter revision and licenses are bundled in `firefox-ios/Client/Assets/AsterFilters/`. All recorded source/rule hashes were verified after downloading the artifact. The converter report records `errorsCount: 89` for unsupported source inputs and `discardedSafariRules: 0`; this is not a claim that every AdGuard rule is supported. Real WebKit compilation passed.

## Local checks

Earlier local verification recorded 58 fixture-server HTTP contract checks covering HEAD, byte ranges, suffix ranges, invalid requests, missing resources and correct payloads. Fixture JavaScript syntax was checked with Node; the original six-second media fixture was confirmed as H.264 video with AAC audio, including HLS segments. Localization string syntax, opaque icon assets and primary palette text contrast were checked. New native source/resources and unit assertions were registered in the Xcode project.

On 20 October, the JavaScript production build passed. The new package auditor passed 25 synthetic contract tests, and the fullscreen observer passed 11 Node contract tests against JavaScript extracted from the generated fixture. These checks cover frozen/stale decoded frames and read-only observation; they do not prove native playback or audit an actual device IPA.

Local checks complement native execution. They do not replace the unexecuted download test, iPhone release compilation, signed installation or physical-device testing.

## Checks still required

- Run the diagnostic candidate and resolve the fullscreen stall using native evidence. Complete all four preflight cases, the full upstream unit plan, all 15 main UI cases, dedicated download and exact file-byte verification for the candidate source.
- Complete the iPhone release build and packaging; audit the actual IPA and record its hash, source/build identity, device platform, extensions, privacy/offline resources and exact filter provenance.
- Provide valid Apple signing and matching provisioning for the app and all six extensions before installation. TestFlight also requires Apple Developer/App Store Connect setup; no signing credentials are configured.
- Test the signed application on a physical iPhone 15 Pro Max.

The existing [native gallery](docs/aster-screenshots/README.md) retains unmodified screenshots from run 38083870485, source `51fe284ead04c0d17b55c51725aa590dd951d031`. Its provenance remains unchanged; run 15's separate gallery preserves its later passing four-case checkpoint.

## Feature and validation limits

Aster is an independent native browser based on Firefox for iOS. It does not implement all Brave features or claim identical parity. Inherited blocking of known fingerprinter URLs is present, but Brave-style canvas/audio fingerprint randomization is not integrated. No dedicated cookie-banner filter or automatic consent-rejection feature is implemented. There is no user-facing strict HTTPS-only mode; inherited automatic HTTPS upgrades are feature-gated on iOS 18.2+ and permit HTTP fallback, with release-channel defaults off and developer/beta defaults on. Real HTTPS upgrade/fallback network behavior remains unverified.

Brave Playlist and a saved-media background-playback library, Brave Sync, Rewards, Wallet, Leo, News and paid VPN services are not implemented. Firefox Account integration remains inherited provider code whose independent identifiers, redirects and end-to-end use are unverified. The Apple-managed default-browser entitlement is not included. Advertising rules are refreshed during builds; this fork does not provide a background advertising-rule updater. Protection depends on the bundled lists and website behavior; no result promises removal of all advertising or tracking.

PiP and AirPlay are enabled in native WebKit configuration, with configuration-level unit assertions; actual PiP/device behavior and AirPlay receivers remain unverified. Simulator decoding of an AAC track is not evidence of audible sound on a physical iPhone. Signed credential extensions, Face ID, protected DRM streams, long-session battery/performance, background audio behavior, complete Arabic translations and accessibility on a physical device require further testing. The latest native run used an iPhone 15 Pro Max simulator and does not certify every supported iOS version. No finite test suite certifies all websites or every browser feature.
