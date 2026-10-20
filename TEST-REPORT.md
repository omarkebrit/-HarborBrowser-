# Aster validation report

The current delivery candidate is full native [run 23](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39406335775), source `4557246b64453abb464844aa8ff4358e90107c5b`. Its 45 contract checks passed; unit, five-preflight, 16-main, isolated-download and device-package outcomes remain pending. It includes the core fixture/UI corrections and hides the unsupported crash-upload control using existing backend eligibility. Collection defaults remain off.

Full [run 22](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39405042843), source `5174b9a6775c0a0ada40bebf7c309ee300cf1bc5`, continues independently to verify the earlier core corrections; its native results remain pending. Run 20 also continues independently.

Native [run 20](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39394936415), source `273578ee85af23845bf517e76572f02a04a3f678`, is in progress. Its 45 local-contract checks passed in CI. Run 20's official unit result is 5,746 passed, one failed and two skipped (5,749 total). All six corrected async Summarize tests and their suite passed; the sole remaining unit failure is the WK WebView observer case's 30-second progress/content-size wait. Its five-case preflight finished with three passes, two failures and zero skips: first-loop rotation setup and tab 14 hittability failed. Its main UI selection passed all 16 cases with zero failures/skips, including all four media transports, first-loop boundary rotation and 25-tab restoration. The isolated download and exact-byte verification steps passed; device-package outcomes remain pending.

[Run 18](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39379658275), attempt 1, source `7788245534fc23c00a93fb8375c83ebce8703a1e`, completed with four preflight passes, 14/15 main UI passes and a passing isolated native download/integrity check. The official full-unit summary records 5,745 passed, two failed and two skipped, out of 5,749. The iPhone release build and actual unsigned-package audit passed, but the IPA was withheld because required tests failed. No full-validation pass or signed installation is established.

The [preserved final evidence](docs/aster-validation/run18/README.md) contains the original summaries, audit, download integrity, source/toolchain and relevant failure attachments with exact hashes. [Recovery run 19](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39394322518), source `7613a000119a4877578a7df070d827e27c8fb954`, extracted run 18's files only; its native job was skipped. Its successful conclusion is not a new native test pass. Production playback behavior was unchanged by run 18's read-only diagnostics, and its passing fullscreen case does not establish a fix for run 17's stall.

## Run 20 unit result and targeted diagnostic

Run 20's official summary records `Failed`: 5,746 passed, one failed, two skipped and zero expected failures, out of 5,749. All six corrected async Summarize tests and the containing suite passed, including `test_summarize_withNotEnoughStartingWords` in 0.198 seconds. The sole failure is `WKEngineWebViewTests/testLoad_callsObservers()`, which exceeded its unchanged 30-second progress/content-size expectations. The WebView has its intended 320×640 frame, but its scroll content size remains zero. The finite-viewport fixture change did not resolve the synchronous wait; run 21's comparison below supports the async-unhosted correction.

The two runtime skips are unchanged upstream cases: [TabEventHandlerTests.testBlankPopupURL](https://github.com/mozilla-mobile/firefox-ios/blob/1a0bf7b01230c165e8d66c7e07a66b7c8f52a83a/firefox-ios/firefox-ios-tests/Tests/ClientTests/TabManagement/TabEventHandlerTests.swift#L40) explicitly skips because it no longer completes after AppDelegate setup changes, and [TestHistory.testRandomThreading](https://github.com/mozilla-mobile/firefox-ios/blob/1a0bf7b01230c165e8d66c7e07a66b7c8f52a83a/firefox-ios/firefox-ios-tests/Tests/ClientTests/TestHistory.swift#L225) skips for upstream issue FXIOS-12339. Both files and the unit test plan match the pinned Firefox 158 baseline byte-for-byte. These runtime counts are separate from the plan's inherited exclusions; Aster introduced no new skip for these failures.

Targeted [diagnostic run 21](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39402334591), source `92473b44727bb14183775748a0d057ff35a0aae3`, finished with 232 passes and one reproduced synchronous-control failure (zero skips). The async unhosted variant passed; the original case is now made async with the same 30-second deadline and eight checks for full run 22. This comparison is not a full validation pass and produced no IPA. The [preserved diagnostic comparison](docs/aster-validation/run21-diagnostic/README.md) contains all four unmodified temporary-state attachments and the official 232-pass/one-failure/zero-skip summary. Its XCTest expected-failure count is zero; the control failure was not waived.

The synchronous unhosted control failed after 32.489 seconds at progress 0.1 without recorded navigation start/commit/finish. Async unhosted passed in 0.963 seconds with actual didStart/didCommit/didFinish, progress 1, title Test Page and content 980×1960. Both hosted variants also passed, while `applicationState` remained nil in all four. The comparison supports the minimal async-unhosted correction without a production or window-hosting change. Full run 22 must still validate the original test and remaining browser requirements.

## Run 20 main UI checkpoint

The later main selection passed all 16 cases with zero failures, skips or expected failures. The [preserved original main checkpoint](docs/aster-validation/run20-main/README.md) contains its official summary, source and toolchain. The acceptance log confirms actual decoded MP4, HLS, iframe and blob iterations; their combined case passed in 65.917 seconds. Strict first-loop-boundary rotation passed in 74.030 seconds, ordinary fullscreen rotation/exit in 61.829 seconds and 25-tab creation/restoration in 597.062 seconds. Every other selected main case passed too.

The boundary case recorded schedule, actual-resize and offset attachments, but their payloads and screenshots are not exported by this checkpoint. Exact offset/image review awaits the full native evidence. This main execution passed its strict assertions; the earlier preflight 3/2 failures and run 17's stall remain separate evidence. It does not establish a production playback fix or override run 20's unit/preflight failures. The isolated download and exact-byte verification steps passed; no full-validation pass or deliverable IPA is established.

## Run 20 preflight failures

The official five-case summary records three passes, two failures, zero skips and zero expected failures. Popup, restrictive autoplay and ordinary fullscreen rotation/exit passed. The [preserved preflight evidence](docs/aster-validation/run20-preflight/README.md) contains the unchanged summary, source/toolchain, original attachment manifest and relevant screenshots/hierarchies.

The first-loop case failed during setup, before its intended rotation. The clock sample was fresh (age 0.0289 seconds), but its epoch 1792488863983 was 6.541 seconds after play anchor 1792488857442 in the six-second clip, and one natural wrap had occurred. The sample reported time 0/playing false. Final portrait evidence then recovered to playing true, time 1.424 and 50 frames, with rotation observation null. This does not establish a persistent freeze or a successful boundary-timed rotation test. Native probe entry at 09:34:18.805 and cleanup exit at 09:34:26.734 record the same portrait parent/window, with no intended rotation. The playback-state callback at 09:34:18.841 is earlier than the setup failure at 09:34:23.983 and must not be treated as a failure-time state sample.

The tab case failed its hittability wait for `Local tab 14 ready`. The screenshot about 1.01 seconds after failure shows the page. The final hierarchy gives its label a finite 16/124/147/24 frame inside contentView 0/59/430/731 and the 430×932 main window. There is no explicit invalid-activation-point error, so run 18's MP4 status failure is not an established explanation. The case did not complete 25-tab creation/restoration. Work on a single-snapshot clock read and rendered-label geometry checks is being prepared and requires new native verification.

## Completed evidence and current requirements

| Area | Run 18 official result | Delivery requirement |
| --- | --- | --- |
| Four media/session preflight cases | 4 passed, 0 failed, 0 skipped, 0 expected failures; two-loop decoded-frame and 25-tab restoration checks passed | Current run 23 requires five cases, including first-loop boundary rotation |
| Full upstream `UnitTest` plan | 5,745 passed, 2 failed, 2 skipped; 5,749 total | Summarize is verified in run 20; resolve the remaining WK observer failure and pass the full plan |
| Main UI selection | 14 passed, 1 failed, 0 skipped; first MP4 status-label hittability failure | Current run 23 requires all 16 cases; run 18 selected 15 |
| Native download and exact file-byte verification | 1 passed, 0 failed, 0 skipped; exact 95-byte SHA-256 check passed | Remains required for the current run 23 candidate |
| Unsigned iPhone release build and actual IPA audit | Passed; build 18.1, arm64 iOS device and six extensions | Tests must also pass before IPA publication |
| Signed installation and physical-device validation | Not performed | Requires valid Apple signing and physical iPhone testing |

The earlier completed native test environment was Xcode 26.5 (17F42), iOS 26.5 (23F77), on an iPhone 15 Pro Max simulator using the standard `macos-26` runner. Results are bounded to their recorded sources and simulator environment.

## Verified native download

Run 18 passed its isolated native download case and the subsequent app-container byte check. `aster-payload.txt` contains exactly 95 bytes with SHA-256 `fa7f6baddf7671ff0f6f7aa8c03fe987c556a4bc590406da2e8d9542bfdb3dbc`. This establishes the fixture download for the recorded source; the failed unit/main UI stages still prevent IPA publication.

## Verified unsigned device package

Run 18 built and audited an actual unsigned iPhone IPA: build `18.1`, 207,494,746 bytes, SHA-256 `e1a064a96f3027356d0be1ee0abf4911eb54438336a3f7e9eca2847d95700274`. The audit confirms arm64 iOS-device binaries, all six extension identities/builds, privacy and offline resources, and exact bundled filter integrity. The package contains 42,195 rules; the checked-in historical snapshot below remains distinct. The IPA was not published because required tests failed. Audit success does not provide Apple signing, installation or a full browser pass.

## Run 18 failures

`SummarizeViewModelTests/test_summarize_withNotEnoughStartingWords()` exceeded its 0.5-second callback expectation. A subsequent xctest crash has capture time 06:45:45.2127 UTC and a late Summarize callback stack. The attachment was exported under `WKEngineWebViewTests/testLoad_callsObservers()`, but that association does not establish a WK-test crash. The WK observer case separately exceeded its 30-second progress/content-size expectations; its root cause is not confirmed.

The main failure was `testMP4HLSIframeAndBlobPlayRealAudioAndVideo()`: XCTest could not determine the hittability of the first MP4's `Audio and video playing` status. The preserved screenshot shows decoded playback with 67 observed frames, media time 5.64, paused false, readyState 4 and no error. Later HLS, iframe and blob iterations did not execute. The separate fullscreen case passed in both preflight and main UI. The rendered-status helper passed all four iterations in run 20’s main execution; the current delivery source still requires its own native verification.

## Verified preflight checkpoints

Run 18's saved `AsterRegressionTests-summary.json` records `result: Passed`, four passes, zero failures, zero skips and zero expected failures. Its recorded source matches `7788245534fc23c00a93fb8375c83ebce8703a1e`. The [preserved run 18 checkpoint](docs/aster-screenshots/regression-run18/README.md) contains two original captures, the official summary and exact source/hash provenance. The environment was Xcode 26.5 (17F42), iOS 26.5 (23F77), on the iPhone 15 Pro Max simulator.

The popup, restrictive-autoplay, fullscreen and 25-tab cases passed in 79.623, 60.387, 67.117 and 613.488 seconds respectively. Fullscreen required two landscape end/start transitions and new decoded frames, followed by fullscreen exit and real native menu/Settings interaction. The tab case loaded 25 unique numbered pages with exact counts, relaunched the process and selected the first tab. All creation used the normal tray; the alternative context-menu and private-mode creation routes remain unverified by this checkpoint.

[Run 15](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38393771825), source `aab3dc3ac23bf2e58c1334920fe70528e9dad527`, also passed its earlier four-case checkpoint. Earlier run 38086721963 attempt 3, source `ae128811a91010fa972eba2849635d289e9b8e78`, passed all four cases but was manually canceled during subsequent unit compilation. Those partial results remain tied to their recorded sources.

## Fullscreen failure and subsequent passing checkpoint

Run 17's popup and restrictive-autoplay cases passed in 114.987 and 74.272 seconds; the 25-tab case passed in 686.101 seconds. The fullscreen case failed after 54.709 seconds at `Missing rendered media text: Fullscreen video playing in landscape`. The official summary records three passes, one failure, zero skips and zero expected failures.

The native recording shows decoded portrait frames near media time 5.167 seconds. After rotation around the six-second loop boundary, the landscape stage is correctly sized but the video remains at time 0.000/frame 0 for about 15 seconds. The old page status retains its previous portrait-playing text; the failure is supported by frozen video frames and the native media time, rather than that stale label alone. The cause remains unconfirmed. The MP4 decodes cleanly across repeated loops with FFmpeg, and local byte-range checks have not identified a fixture-server defect. The [preserved run 17 failure evidence](docs/aster-screenshots/regression-run17/README.md) includes both original captures, the native hierarchy, official summary and exact source/hash provenance.

Run 18's JavaScript records media time, paused/ended flags, readiness/network state, errors, decoded frames and recent media events. Its screenshots and decoded-frame evidence are valid. The native Client probes were compiled out: Fennec's Debug Swift flags include `MOCKABLE_STORE` and `MOZ_CHANNEL_developer`, but omit Swift `DEBUG`. No `AsterFullscreenProbe` lines appear in its file logs. The guard change to `#if DEBUG || MOZ_CHANNEL_developer` in `WebviewViewController.swift` is now native-verified in run 20 while still excluding the release channel. Its logs contain 28 legacy probe lines, zero engine probe lines and zero reparent probe lines across Firefox.log and Firefox.1.log. The durable preflight set includes a derived exact-line excerpt with full source-log hashes and a separate derivation manifest.

Run 18 passed the stronger two-loop fullscreen case, including exit and native menu/Settings interaction. Its recorded rotation resize occurred at media time 4.075 seconds in the six-second clip. Two healthy landscape end/start transitions therefore do not exercise run 17's combined rotation/first-loop-boundary timing. Run 20's earlier preflight boundary case failed setup before rotation; the later main execution passed the strict case, with exact offset/image review pending. Playback code was unchanged; the stall's cause remains unconfirmed, and this pass does not establish a fix.

## Current native candidate

Current delivery run 23 requires five preflight/16 main/one download selections and the full unit plan. Its native outcomes remain pending; run 22 independently verifies the shared core corrections. Run 20 verified the Summarize correction but failed its synchronous WK observer case and two preflight cases; its later main selection passed all 16 cases. Run 19 was extraction-only. The separate first-loop rotation case uses a read-only epoch clock, a fixed play-tap anchor and the actual first-resize epoch. Run 20's earlier preflight failed setup before rotation, while its later main case passed; run 22 pairs portrait status and the clock from one snapshot to reduce observation delay. The actual resize timing and subsequent decoded-frame checks remain strict. The Client probe guard is native-verified in run 20.

Run 20's verified Summarize fixture correction makes all six main-actor tests async with the same 0.5-second deadlines and capture their mock by value to avoid a late callback dereferencing torn-down test state. Run 20's failing synchronous WK observer case used a finite 320×640 viewport and local tall HTML, with a stronger content-size predicate requiring width greater than zero and height greater than the 640-point viewport. All eight observers, progress==1, the 30-second deadline and delegate/leak assertions remain in run 22's minimal async version. These are test-fixture corrections, not a proven production playback fix.

The AutoFill declaration correction in run 22 restores the main app's entitlement to match upstream and its extension. It is not included in run 20's source and does not certify signed AutoFill. The actual unsigned IPA must still be inspected for embedded entitlements before promising compatibility with a signing tool. [Signing requirements](SIGNING-REQUIREMENTS.md) record this remaining installation work and conditional phone-only routes.

Run 23 additionally hides the unsupported crash-upload control. `DefaultCrashManager.supportsCrashReporting` exposes the existing two-Mozilla-identifier eligibility rule, and Main Settings includes the row only when supported. Aster crash upload remains unsupported; collection defaults and the release-name override behavior are unchanged. The control change is included in current native validation, with results pending.

The current run 23 strict selection requires five preflight cases, 16 main UI cases and one isolated download case, all without skips or failures, plus the full unit plan, download-byte verification and device-package audit. That is 22 UI test executions covering 17 unique cases. These requirements do not change run 18's recorded four-case preflight or 15-case main selection.

## Verified document-readiness change

Run 16 failed its 10-second existence wait for `Local tab 7 ready`, before any hittability assertion. Its fixture request arrived about 23 seconds after Return; final evidence showed the correct document and native count 7. No production cache or timer defect was verified.

Run 17 gave only the 25-tab stress case a 30-second document-existence budget and passed it. Other existence defaults and the subsequent 10/20-second hittability budgets were unchanged. All 25 numbered loads, exact counts, process relaunch and first-tab tray selection remained required. This proves that scoped readiness change for run 17's source, without establishing the owner of run 16's delay.

## Verified search fixture correction

`SearchTests.testSuggestClient` passed in run 18 in 0.709 seconds. Its main-actor async fixture yields while the URL session delivers callbacks on the main queue, retains the server through both real localhost queries and stops it afterward. Both 10-second deadlines, six exact suggestion assertions and error checks remain. This resolves the earlier unverified search-fixture result; run 18's two unit failures were in the separate cases identified above.

## Evidence checkpoint

Run 18's strict four-pass/zero-failure/zero-skip checkpoint was uploaded as artifact `12247766739` (122,240,494 bytes), despite the earlier unit-stage failure. Its result bundle, summary, attachments, logs and recorded source establish a partial preflight result only. The small permanent capture set preserves unmodified files and their SHA-256 hashes without copying the video or result bundle.

The final original native evidence artifact is `12251425178`. Recovery artifact `12251460795` contains extracted copies; native source identity remains run 18's `7788245`, not the recovery workflow's source.

Artifacts use an `attempt-N` suffix. The full native evidence is `Aster-native-validation-evidence-attempt-N`; filter evidence is `aster-ad-filters-attempt-N`. The future IPA artifact is `Aster-iPhone-UNSIGNED-needs-signing-attempt-N`, containing `Aster-UNSIGNED-needs-signing.ipa`. A checkpoint or filter artifact is not an installable app. An IPA is published only after all required native tests, download-integrity verification, device build/package and actual-package audit succeed. Artifact retention is seven days.

## Retained advertising snapshot

The checked-in pack is the exact snapshot tested and WebKit-compiled in run 38083870485: 40,723 rules, SHA-256 `3036112f5339915d24298fcbcd241f44b3a2f6b53e7ab4090ae2924f179f3ce3`. Its metadata, raw sources, converter revision and licenses are bundled in `firefox-ios/Client/Assets/AsterFilters/`. All recorded source/rule hashes were verified after downloading the artifact. The converter report records `errorsCount: 89` for unsupported source inputs and `discardedSafariRules: 0`; this is not a claim that every AdGuard rule is supported. Real WebKit compilation passed.

## Local checks

Earlier local verification recorded 58 fixture-server HTTP contract checks covering HEAD, byte ranges, suffix ranges, invalid requests, missing resources and correct payloads. Fixture JavaScript syntax was checked with Node; the original six-second media fixture was confirmed as H.264 video with AAC audio, including HLS segments. Localization string syntax, opaque icon assets and primary palette text contrast were checked. New native source/resources and unit assertions were registered in the Xcode project.

On 20 October, the JavaScript production build passed. The new package auditor passed 25 synthetic contract tests, and the fullscreen observer passed 20 Node contract tests against JavaScript extracted from the generated fixture. These checks cover frozen/stale decoded frames and read-only observation; they do not replace native playback or actual-package checks; run 18 separately completed its real IPA audit.

These local checks complement native execution. Run 18's download and iPhone release compilation/package audit are verified; failed tests, signed installation and physical-device testing remain unresolved.

## Checks still required

- Verify current run 23's minimal async WK observer correction, first-loop single-snapshot clock and tab-geometry assertion, plus the MP4 status-label and timing-sensitive media cases. Run 20 has verified the Summarize fixture correction. Complete the full unit plan, all 16 main UI cases, all five preflight cases, dedicated download and exact file-byte verification for the current delivery candidate. Investigate any recurrence of the earlier fullscreen stall using the new native diagnostics.
- Repeat the iPhone release build/package audit for the corrected delivery source, retaining its exact package hash and provenance. Run 18's completed audit applies only to its recorded source.
- Provide valid Apple signing and matching provisioning for the app and all six extensions before installation. TestFlight also requires Apple Developer/App Store Connect setup; no signing credentials are configured.
- Test the signed application on a physical iPhone 15 Pro Max. The [Arabic device checklist](IPHONE-CHECK-AR.md) records the outstanding physical checks, all explicitly unexecuted.

The existing [native gallery](docs/aster-screenshots/README.md) retains unmodified screenshots from run 38083870485, source `51fe284ead04c0d17b55c51725aa590dd951d031`. Its provenance remains unchanged; run 15's separate gallery preserves its later passing four-case checkpoint.

## Feature and validation limits

Aster is an independent native browser based on Firefox for iOS. It does not implement all Brave features or claim identical parity. Inherited blocking of known fingerprinter URLs is present, but Brave-style canvas/audio fingerprint randomization is not integrated. No dedicated cookie-banner filter or automatic consent-rejection feature is implemented. There is no user-facing strict HTTPS-only mode; inherited automatic HTTPS upgrades are feature-gated on iOS 18.2+ and permit HTTP fallback, with release-channel defaults off and developer/beta defaults on. Real HTTPS upgrade/fallback network behavior remains unverified.

Brave Playlist and a saved-media background-playback library, Brave Sync, Rewards, Wallet, Leo, News and paid VPN services are not implemented. Firefox Account integration remains inherited provider code whose independent identifiers, redirects and end-to-end use are unverified. The Apple-managed default-browser entitlement is not included. Advertising rules are refreshed during builds; this fork does not provide a background advertising-rule updater. Protection depends on the bundled lists and website behavior; no result promises removal of all advertising or tracking.

PiP and AirPlay are enabled in native WebKit configuration, with configuration-level unit assertions; actual PiP/device behavior and AirPlay receivers remain unverified. Simulator decoding of an AAC track is not evidence of audible sound on a physical iPhone. Signed credential extensions, Face ID, protected DRM streams, long-session battery/performance, background audio behavior, complete Arabic translations and accessibility on a physical device require further testing. The latest native run used an iPhone 15 Pro Max simulator and does not certify every supported iOS version. No finite test suite certifies all websites or every browser feature.
