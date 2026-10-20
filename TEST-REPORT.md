# Aster validation report

Validation is in progress as of 20 October 2026. [Run 18](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39379658275), attempt 1, source `7788245534fc23c00a93fb8375c83ebce8703a1e`, has an official preflight result of four passes, zero failures, zero skips and zero expected failures. It includes fresh decoded frames through two landscape end/start transitions and 25-tab creation/restoration. Simulator build/signing verification passed, but the full unit stage failed; diagnosis awaits final logs. The 15-case main UI stage also failed; its failing cases and official count are not yet available. The isolated native download and exact 95-byte integrity check passed. Device build/audit results remain pending. No production IPA or full-validation pass is available yet.

Production playback behavior was unchanged by this candidate's read-only media diagnostics. This passing checkpoint does not establish the cause or a fix for run 17's fullscreen stall. CI runs units first and independently collects later stages despite an earlier failure; IPA publication still requires every required check to pass.

## Completed evidence and current requirements

| Area | Latest evidence | Current requirement |
| --- | --- | --- |
| Four media/session preflight cases | Run 18: official 4 passed, 0 failed, 0 skipped, 0 expected failures; stronger two-loop decoded-frame assertion and 25-tab restoration passed | Preserve this four-case checkpoint; the prepared next candidate requires all five cases, including boundary-timed rotation |
| Full upstream `UnitTest` plan | Run 18's unit stage failed; diagnosis and individual test results await final logs. Earlier [run 38083870485](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38083870485), source `51fe284ead04c0d17b55c51725aa590dd951d031`, passed | Diagnose and resolve the failure; full plan must pass for delivery |
| Main local acceptance and selected upstream UI tests | Run 18's main stage failed; failing cases and official count await final evidence. Run 38083870485 passed 14/15, failing the fullscreen post-rotation toolbar assertion | The prepared next candidate requires all 16 selected cases; run 18 retains its original 15-case selection |
| Native download and exact file-byte verification | Run 18 passed the isolated native case and exact 95-byte SHA-256 check | Passed for run 18; remains required for the next delivery candidate |
| Unsigned iPhone release build and actual IPA audit | No device IPA produced or audited | Device compilation, package integrity and all publication gates must pass |
| Signed installation and physical-device validation | Not performed | Requires Apple signing and physical iPhone testing |

The earlier completed native test environment was Xcode 26.5 (17F42), iOS 26.5 (23F77), on an iPhone 15 Pro Max simulator using the standard `macos-26` runner. Results are bounded to their recorded sources and simulator environment.

## Verified native download

Run 18 passed its isolated native download case and the subsequent app-container byte check. `aster-payload.txt` contains exactly 95 bytes with SHA-256 `fa7f6baddf7671ff0f6f7aa8c03fe987c556a4bc590406da2e8d9542bfdb3dbc`. This establishes the fixture download for the recorded source; it does not override the failed unit/main UI stages or complete the pending device-package audit.

## Verified preflight checkpoints

Run 18's saved `AsterRegressionTests-summary.json` records `result: Passed`, four passes, zero failures, zero skips and zero expected failures. Its recorded source matches `7788245534fc23c00a93fb8375c83ebce8703a1e`. The [preserved run 18 checkpoint](docs/aster-screenshots/regression-run18/README.md) contains two original captures, the official summary and exact source/hash provenance. The environment was Xcode 26.5 (17F42), iOS 26.5 (23F77), on the iPhone 15 Pro Max simulator.

The popup, restrictive-autoplay, fullscreen and 25-tab cases passed in 79.623, 60.387, 67.117 and 613.488 seconds respectively. Fullscreen required two landscape end/start transitions and new decoded frames, followed by fullscreen exit and real native menu/Settings interaction. The tab case loaded 25 unique numbered pages with exact counts, relaunched the process and selected the first tab. All creation used the normal tray; the alternative context-menu and private-mode creation routes remain unverified by this checkpoint.

[Run 15](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38393771825), source `aab3dc3ac23bf2e58c1334920fe70528e9dad527`, also passed its earlier four-case checkpoint. Earlier run 38086721963 attempt 3, source `ae128811a91010fa972eba2849635d289e9b8e78`, passed all four cases but was manually canceled during subsequent unit compilation. Those partial results remain tied to their recorded sources.

## Fullscreen failure and subsequent passing checkpoint

Run 17's popup and restrictive-autoplay cases passed in 114.987 and 74.272 seconds; the 25-tab case passed in 686.101 seconds. The fullscreen case failed after 54.709 seconds at `Missing rendered media text: Fullscreen video playing in landscape`. The official summary records three passes, one failure, zero skips and zero expected failures.

The native recording shows decoded portrait frames near media time 5.167 seconds. After rotation around the six-second loop boundary, the landscape stage is correctly sized but the video remains at time 0.000/frame 0 for about 15 seconds. The old page status retains its previous portrait-playing text; the failure is supported by frozen video frames and the native media time, rather than that stale label alone. The cause remains unconfirmed. The MP4 decodes cleanly across repeated loops with FFmpeg, and local byte-range checks have not identified a fixture-server defect. The [preserved run 17 failure evidence](docs/aster-screenshots/regression-run17/README.md) includes both original captures, the native hierarchy, official summary and exact source/hash provenance.

Run 18's JavaScript records media time, paused/ended flags, readiness/network state, errors, decoded frames and recent media events. Its screenshots and decoded-frame evidence are valid. The native Client probes were compiled out: Fennec's Debug Swift flags include `MOCKABLE_STORE` and `MOZ_CHANNEL_developer`, but omit Swift `DEBUG`. No `AsterFullscreenProbe` lines appear in its file logs. The prepared guard change to `#if DEBUG || MOZ_CHANNEL_developer` in `WebviewViewController.swift` enables those read-only probes for a future developer build while leaving the release channel excluded; native runtime verification of that guard change remains pending.

Run 18 passed the stronger two-loop fullscreen case, including exit and native menu/Settings interaction. Its recorded rotation resize occurred at media time 4.075 seconds in the six-second clip. Two healthy landscape end/start transitions therefore do not exercise run 17's combined rotation/first-loop-boundary timing. A separate explicit boundary-timing test is now prepared locally for the next candidate; it has not run natively. Playback code was unchanged; the stall's cause remains unconfirmed, and this pass does not establish a fix.

## Prepared next candidate

The prepared HEAD candidate, with five preflight/16 main/one download selections, has not been launched or natively verified. It adds a separate first-loop rotation case; run 18's passing fullscreen case is unchanged. The new case uses a read-only epoch clock, a fixed play-tap anchor and the actual first-resize epoch to check rotation timing at the first loop boundary. Its native runtime result remains pending, as does the Client probe guard change described above.

The next strict selection requires five preflight cases, 16 main UI cases and one isolated download case, all without skips or failures, plus the full unit plan, download-byte verification and device-package audit. That is 22 UI test executions covering 17 unique cases. These future requirements do not change run 18's recorded four-case preflight or 15-case main selection.

## Verified document-readiness change

Run 16 failed its 10-second existence wait for `Local tab 7 ready`, before any hittability assertion. Its fixture request arrived about 23 seconds after Return; final evidence showed the correct document and native count 7. No production cache or timer defect was verified.

Run 17 gave only the 25-tab stress case a 30-second document-existence budget and passed it. Other existence defaults and the subsequent 10/20-second hittability budgets were unchanged. All 25 numbered loads, exact counts, process relaunch and first-tab tray selection remained required. This proves that scoped readiness change for run 17's source, without establishing the owner of run 16's delay.

## Current unit-fixture fix

Run 15's job log records `SearchTests.testSuggestClient` timing out while waiting for its first local suggestion response. The server served successful responses after that deadline; server deallocation is not established as the cause. The fix introduced in run 16 and retained in run 17 makes this main-actor test async so it yields while the production URL session delivers callbacks on the main queue. It retains the server through both queries and stops it afterward. Both 10-second deadlines, real localhost requests, six exact suggestion assertions and error checks are unchanged. No production browser code changed. Runs 16 and 17 did not reach units. Run 18 reached the unit stage and failed, but the individual result of this search test and the failure's cause remain unknown until the final logs are available.

The candidate runs units first so this fixture change can be checked before the media preflight. Independent subsequent stages collect additional native results despite earlier failures. Official summaries are exported for every result bundle present. The actual device package is audited even when an earlier test fails; failed runs preserve audit JSON/logs, while IPA bytes are published only after all required checks pass.

## Evidence checkpoint

Run 18's strict four-pass/zero-failure/zero-skip checkpoint was uploaded as artifact `12247766739` (122,240,494 bytes), despite the earlier unit-stage failure. Its result bundle, summary, attachments, logs and recorded source establish a partial preflight result only. The small permanent capture set preserves unmodified files and their SHA-256 hashes without copying the video or result bundle.

Artifacts use an `attempt-N` suffix. The full native evidence is `Aster-native-validation-evidence-attempt-N`; filter evidence is `aster-ad-filters-attempt-N`. The future IPA artifact is `Aster-iPhone-UNSIGNED-needs-signing-attempt-N`, containing `Aster-UNSIGNED-needs-signing.ipa`. A checkpoint or filter artifact is not an installable app. An IPA is published only after all required native tests, download-integrity verification, device build/package and actual-package audit succeed. Artifact retention is seven days.

## Retained advertising snapshot

The checked-in pack is the exact snapshot tested and WebKit-compiled in run 38083870485: 40,723 rules, SHA-256 `3036112f5339915d24298fcbcd241f44b3a2f6b53e7ab4090ae2924f179f3ce3`. Its metadata, raw sources, converter revision and licenses are bundled in `firefox-ios/Client/Assets/AsterFilters/`. All recorded source/rule hashes were verified after downloading the artifact. The converter report records `errorsCount: 89` for unsupported source inputs and `discardedSafariRules: 0`; this is not a claim that every AdGuard rule is supported. Real WebKit compilation passed.

## Local checks

Earlier local verification recorded 58 fixture-server HTTP contract checks covering HEAD, byte ranges, suffix ranges, invalid requests, missing resources and correct payloads. Fixture JavaScript syntax was checked with Node; the original six-second media fixture was confirmed as H.264 video with AAC audio, including HLS segments. Localization string syntax, opaque icon assets and primary palette text contrast were checked. New native source/resources and unit assertions were registered in the Xcode project.

On 20 October, the JavaScript production build passed. The new package auditor passed 25 synthetic contract tests, and the fullscreen observer passed 20 Node contract tests against JavaScript extracted from the generated fixture. These checks cover frozen/stale decoded frames and read-only observation; they do not prove native playback or audit an actual device IPA.

These local checks complement native execution. Run 18's download is now verified, while iPhone release compilation/package audit, signed installation and physical-device testing remain pending.

## Checks still required

- Diagnose and resolve run 18's unit and main UI failures from final logs. Complete the full unit plan, all 16 main UI cases, all five preflight cases, dedicated download and exact file-byte verification for the next delivery candidate. Investigate any recurrence of the earlier fullscreen stall using the new native diagnostics.
- Complete the iPhone release build and packaging; audit the actual IPA and record its hash, source/build identity, device platform, extensions, privacy/offline resources and exact filter provenance.
- Provide valid Apple signing and matching provisioning for the app and all six extensions before installation. TestFlight also requires Apple Developer/App Store Connect setup; no signing credentials are configured.
- Test the signed application on a physical iPhone 15 Pro Max.

The existing [native gallery](docs/aster-screenshots/README.md) retains unmodified screenshots from run 38083870485, source `51fe284ead04c0d17b55c51725aa590dd951d031`. Its provenance remains unchanged; run 15's separate gallery preserves its later passing four-case checkpoint.

## Feature and validation limits

Aster is an independent native browser based on Firefox for iOS. It does not implement all Brave features or claim identical parity. Inherited blocking of known fingerprinter URLs is present, but Brave-style canvas/audio fingerprint randomization is not integrated. No dedicated cookie-banner filter or automatic consent-rejection feature is implemented. There is no user-facing strict HTTPS-only mode; inherited automatic HTTPS upgrades are feature-gated on iOS 18.2+ and permit HTTP fallback, with release-channel defaults off and developer/beta defaults on. Real HTTPS upgrade/fallback network behavior remains unverified.

Brave Playlist and a saved-media background-playback library, Brave Sync, Rewards, Wallet, Leo, News and paid VPN services are not implemented. Firefox Account integration remains inherited provider code whose independent identifiers, redirects and end-to-end use are unverified. The Apple-managed default-browser entitlement is not included. Advertising rules are refreshed during builds; this fork does not provide a background advertising-rule updater. Protection depends on the bundled lists and website behavior; no result promises removal of all advertising or tracking.

PiP and AirPlay are enabled in native WebKit configuration, with configuration-level unit assertions; actual PiP/device behavior and AirPlay receivers remain unverified. Simulator decoding of an AAC track is not evidence of audible sound on a physical iPhone. Signed credential extensions, Face ID, protected DRM streams, long-session battery/performance, background audio behavior, complete Arabic translations and accessibility on a physical device require further testing. The latest native run used an iPhone 15 Pro Max simulator and does not certify every supported iOS version. No finite test suite certifies all websites or every browser feature.
