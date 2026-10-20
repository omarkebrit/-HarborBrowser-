# Aster validation report

**No downloadable release or completed full-validation pass is available.** Full [run 26](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39420482530), source `82dd060ead28e7e0170218a342fbcb991bbeef58`, started on 20 October at 12:12:25 UTC. Its 49 CI contract checks passed (24 Node and 25 Python); native units, five preflight cases, 16 main UI cases, isolated download/integrity and device build/package audit remain pending.

Media-only [diagnostic 24](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39414241881), source `e0f89e5f8ce34e6faa230dac404b5a1434712486`, passed both selected cases with zero failures, skips or expected failures. Isolated-WebEngine [diagnostic 25](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39414543028), source `1617b9a76839208c5f2ac533a646226929491787`, passed 230/0 failed/0 skipped/0 expected failures. Neither produces an IPA or replaces run 26’s full validation. The [preserved WebEngine checkpoint](docs/aster-validation/run25-diagnostic/README.md) records its original source and results.

Full [run 23](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39406335775), source `4557246b64453abb464844aa8ff4358e90107c5b`, passed units 5,747/0 failed/2 upstream skips but failed preflight 3/2, blocking IPA publication; main UI finished 15 passed/one failed, download/byte-verification steps passed and device outcomes remain pending. Parallel [run 22](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39405042843), source `5174b9a6775c0a0ada40bebf7c309ee300cf1bc5`, recorded units 5,745/2 failed/2 skipped and preflight 4 passed/one failed.

Native [run 20](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39394936415), source `273578ee85af23845bf517e76572f02a04a3f678`, completed with required unit/preflight failures. Its 45 local-contract checks passed in CI. Run 20's official unit result is 5,746 passed, one failed and two skipped (5,749 total). All six corrected async Summarize tests and their suite passed; the sole remaining unit failure is the WK WebView observer case's 30-second progress/content-size wait. Its five-case preflight finished with three passes, two failures and zero skips: first-loop rotation setup and tab 14 hittability failed. Its main UI selection passed all 16 cases with zero failures/skips, including all four media transports, first-loop boundary rotation and 25-tab restoration. The official isolated download result is one pass with zero failures/skips and exact 95-byte integrity. The original CI device build/package audit passed for build 20.1; IPA publication was skipped after the required unit/preflight failures.

[Run 18](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39379658275), attempt 1, source `7788245534fc23c00a93fb8375c83ebce8703a1e`, completed with four preflight passes, 14/15 main UI passes and a passing isolated native download/integrity check. The official full-unit summary records 5,745 passed, two failed and two skipped, out of 5,749. The iPhone release build and actual unsigned-package audit passed, but the IPA was withheld because required tests failed. No full-validation pass or signed installation is established.

The [preserved final evidence](docs/aster-validation/run18/README.md) contains the original summaries, audit, download integrity, source/toolchain and relevant failure attachments with exact hashes. [Recovery run 19](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39394322518), source `7613a000119a4877578a7df070d827e27c8fb954`, extracted run 18's files only; its native job was skipped. Its successful conclusion is not a new native test pass. Production playback behavior was unchanged by run 18's read-only diagnostics, and its passing fullscreen case does not establish a fix for run 17's stall.

## Run 20 final outcome

Run 20 completed with required failures: units 5,746 passed/one failed/two skipped and preflight 3 passed/two failed/zero skipped. Main UI passed 16/0/0 and the official isolated download passed 1/0/0. The downloaded 95-byte file has SHA-256 `fa7f6baddf7671ff0f6f7aa8c03fe987c556a4bc590406da2e8d9542bfdb3dbc`.

The original CI iPhone build/package audit passed: build 20.1, arm64 iOS device and six extensions, 207,496,026 bytes, reported SHA-256 `24e29193921ac2ecf3fe7e4862ee7ff8d871befdc96abd3919401e755b0bb167`. IPA publication was skipped because of the unit/preflight failures. The actual IPA binary has not been downloaded or independently audited; this records the original CI audit report. The [preserved final proof](docs/aster-validation/run20-final/README.md) applies only to source `273578ee85af23845bf517e76572f02a04a3f678`, not current run 26.

## Run 23 verified full unit plan

Run 23’s official summary records `Passed`: 5,747 passed, zero failed, two runtime skips and zero expected failures, out of 5,749. The cleaned original `testLoad_callsObservers` passed in 2.525 seconds without temporary diagnostic/window wrappers. All six corrected Summarize cases and their suite passed; the not-enough-starting-words case took 0.153 seconds. The same upstream `testBlankPopupURL` and `testRandomThreading` skips remain, with their original reasons documented below.

The [preserved unit checkpoint](docs/aster-validation/run23-unit/README.md) contains the complete unchanged summary, source and toolchain. A separately identified derived excerpt preserves 13 exact original byte-lines for the corrected cases and skip reasons/results, with full source-log hash/size and matching rules. Simulator host entitlement verification also passed. The later preflight failed 3/2; this passing unit checkpoint does not override that failure or establish a full browser-validation pass, IPA delivery or physical-device result.

## Run 22 unit failure checkpoint

The [preserved original unit summary](docs/aster-validation/run22-unit/README.md), source `5174b9a6775c0a0ada40bebf7c309ee300cf1bc5`, records 5,745 passed, two failed, two skipped and zero expected failures, out of 5,749. All six corrected Summarize cases passed.

The async original WK observer case exceeded its 30-second progress/content-size expectations while its WebProcess was reported unresponsive. No final progress probe value was recorded. The separate `TabWebViewTests.testBasicTabWebView_doesntLeak` failed its inherited weak-reference teardown assertion; the retaining owner is unknown. That unchanged case passed in runs 18, 20 and 23. Neither failure is waived, and no production retention fix is established.

## Run 23 preflight failure checkpoint

Run 23's official preflight result is three passes, two failures, zero skips and zero expected failures. Popup, restrictive-autoplay and ordinary fullscreen cases passed. The [preserved original checkpoint](docs/aster-validation/run23-preflight/README.md) contains the summary, source/toolchain, schedule and final boundary/tab evidence with exact hashes. These failures block IPA publication even if later stages pass.

The boundary case failed on missing `Fullscreen first-loop boundary rotation observed`. Its schedule had fresh portrait playback, zero prior wraps and a request 332.577ms before the predicted boundary. Actual native orientation changed to landscape, but the page's rotation observation remained null. Final AX shows playing true, time 4.837, 258 frames, two landscape loops, three total wraps, readyState 4 and no error. This is a missing observation latch, not evidence of frozen playback; the first-landscape timing assertion did not pass.

The tab case exceeded its 10-second rendered-geometry wait for `Local tab 18 ready` while making three sequential frame-snapshot lookups. The final screenshot and whole-app hierarchy show that page and count 18; the text-only debug snapshot had nonfinite ancestor frames. The case did not complete 25-tab creation/restoration. The one-snapshot tab helper and stage-layout observation change later passed diagnostic 24's isolated two-case selection; run 26’s full native results remain pending. No production playback fix is established. The [main checkpoint](docs/aster-validation/run23-main/README.md) later recorded 15 passes and one missing-boundary-text failure. Its actual main-execution frames await final export; no playback inference is made from this shared failure text alone. Download/byte-verification steps passed; device results remain pending.

## Run 20 unit result and targeted diagnostic

Run 20's official summary records `Failed`: 5,746 passed, one failed, two skipped and zero expected failures, out of 5,749. All six corrected async Summarize tests and the containing suite passed, including `test_summarize_withNotEnoughStartingWords` in 0.198 seconds. The sole failure is `WKEngineWebViewTests/testLoad_callsObservers()`, which exceeded its unchanged 30-second progress/content-size expectations. The WebView has its intended 320×640 frame, but its scroll content size remains zero. The finite-viewport fixture change did not resolve the synchronous wait; run 21's comparison below supports the async-unhosted correction.

The two runtime skips are unchanged upstream cases: [TabEventHandlerTests.testBlankPopupURL](https://github.com/mozilla-mobile/firefox-ios/blob/1a0bf7b01230c165e8d66c7e07a66b7c8f52a83a/firefox-ios/firefox-ios-tests/Tests/ClientTests/TabManagement/TabEventHandlerTests.swift#L40) explicitly skips because it no longer completes after AppDelegate setup changes, and [TestHistory.testRandomThreading](https://github.com/mozilla-mobile/firefox-ios/blob/1a0bf7b01230c165e8d66c7e07a66b7c8f52a83a/firefox-ios/firefox-ios-tests/Tests/ClientTests/TestHistory.swift#L225) skips for upstream issue FXIOS-12339. Both files and the unit test plan match the pinned Firefox 158 baseline byte-for-byte. These runtime counts are separate from the plan's inherited exclusions; Aster introduced no new skip for these failures.

Targeted [diagnostic run 21](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39402334591), source `92473b44727bb14183775748a0d057ff35a0aae3`, finished with 232 passes and one reproduced synchronous-control failure (zero skips). The async unhosted variant passed; the original case is now made async with the same 30-second deadline and eight checks for full run 22. This comparison is not a full validation pass and produced no IPA. The [preserved diagnostic comparison](docs/aster-validation/run21-diagnostic/README.md) contains all four unmodified temporary-state attachments and the official 232-pass/one-failure/zero-skip summary. Its XCTest expected-failure count is zero; the control failure was not waived.

The synchronous unhosted control failed after 32.489 seconds at progress 0.1 without recorded navigation start/commit/finish. Async unhosted passed in 0.963 seconds with actual didStart/didCommit/didFinish, progress 1, title Test Page and content 980×1960. Both hosted variants also passed, while `applicationState` remained nil in all four. The comparison supported the minimal async-unhosted correction without a production or window-hosting change. Full run 22 subsequently failed the original WK observer and the separate tab leak assertion, as recorded above.

## Run 20 main UI checkpoint

The later main selection passed all 16 cases with zero failures, skips or expected failures. The [preserved original main checkpoint](docs/aster-validation/run20-main/README.md) contains its official summary, source and toolchain. The acceptance log confirms actual decoded MP4, HLS, iframe and blob iterations; their combined case passed in 65.917 seconds. Strict first-loop-boundary rotation passed in 74.030 seconds, ordinary fullscreen rotation/exit in 61.829 seconds and 25-tab creation/restoration in 597.062 seconds. Every other selected main case passed too.

The early main checkpoint did not export its schedule/offset/image payloads. The final evidence now confirms a first actual landscape resize 233.201ms after the predicted first boundary, inside the required −750/+500ms window. The original captures progress from 55 frames at resize to 109 frames in landscape and 215 after two additional landscape loops, with three total wraps. This main execution passed its strict assertions; the earlier preflight 3/2 failures and run 17's stall remain separate evidence. It does not establish a production playback fix or override run 20's unit/preflight failures. The isolated download and exact-byte verification steps passed; no full-validation pass or deliverable IPA is established.

## Run 20 preflight failures

The official five-case summary records three passes, two failures, zero skips and zero expected failures. Popup, restrictive autoplay and ordinary fullscreen rotation/exit passed. The [preserved preflight evidence](docs/aster-validation/run20-preflight/README.md) contains the unchanged summary, source/toolchain, original attachment manifest and relevant screenshots/hierarchies.

The first-loop case failed during setup, before its intended rotation. The clock sample was fresh (age 0.0289 seconds), but its epoch 1792488863983 was 6.541 seconds after play anchor 1792488857442 in the six-second clip, and one natural wrap had occurred. The sample reported time 0/playing false. Final portrait evidence then recovered to playing true, time 1.424 and 50 frames, with rotation observation null. This does not establish a persistent freeze or a successful boundary-timed rotation test. Native probe entry at 09:34:18.805 and cleanup exit at 09:34:26.734 record the same portrait parent/window, with no intended rotation. The playback-state callback at 09:34:18.841 is earlier than the setup failure at 09:34:23.983 and must not be treated as a failure-time state sample.

The tab case failed its hittability wait for `Local tab 14 ready`. The screenshot about 1.01 seconds after failure shows the page. The final hierarchy gives its label a finite 16/124/147/24 frame inside contentView 0/59/430/731 and the 430×932 main window. There is no explicit invalid-activation-point error, so run 18's MP4 status failure is not an established explanation. The case did not complete 25-tab creation/restoration. Later fixture changes are recorded below; run 26’s full native verification remains pending.

## Completed evidence and current requirements

| Area | Run 18 official result | Delivery requirement |
| --- | --- | --- |
| Four media/session preflight cases | 4 passed, 0 failed, 0 skipped, 0 expected failures; two-loop decoded-frame and 25-tab restoration checks passed | Run 26 requires five cases, including first-loop boundary rotation; results pending |
| Full upstream `UnitTest` plan | 5,745 passed, 2 failed, 2 skipped; 5,749 total | Run 23 passed this plan; run 26’s full-plan result with the new fixture is pending |
| Main UI selection | 14 passed, 1 failed, 0 skipped; first MP4 status-label hittability failure | Run 26 requires all 16 cases; results pending; run 18 selected 15 |
| Native download and exact file-byte verification | 1 passed, 0 failed, 0 skipped; exact 95-byte SHA-256 check passed | Required in run 26; results pending |
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

Run 18 passed the stronger two-loop fullscreen case, including exit and native menu/Settings interaction. Its recorded rotation resize occurred at media time 4.075 seconds in the six-second clip. Two healthy landscape end/start transitions therefore do not exercise run 17's combined rotation/first-loop-boundary timing. Run 20's earlier preflight boundary case failed setup before rotation; the later main execution passed the strict case, now confirmed by the original +233.201ms actual-resize offset and advancing decoded-frame captures. Playback code was unchanged; the stall's cause remains unconfirmed, and this pass does not establish a fix.

## Current run 26 and isolated diagnostics

The media diagnostic 24 uses one coherent AX snapshot for tab geometry and a ResizeObserver latch for the first actual fullscreen-stage layout crossing, recording its source. It requests rotation at B−0.75 seconds, the lower edge of the unchanged actual timing window [−0.75,+0.5]. The two fresh landscape-loop and 25-tab assertions remain required. Its 24 observation contracts, Python compilation, production JavaScript build and actionlint checks passed locally. The official isolated native selection passed both cases with zero failures, skips or expected failures, and simulator host entitlement verification passed. The [preserved original media evidence](docs/aster-validation/run24-media/README.md) records the first ResizeObserver crossing at +0.376652717590332 seconds inside the unchanged [−0.75,+0.5] window, advancing 53→108→183 decoded frames through two further landscape loops, followed by fullscreen exit/native interaction and 25-tab process restoration. This diagnostic did not run the full unit/browser plan or produce an IPA.

WebEngine diagnostic 25 adds a 28-line visible-window fixture only to the original WK load-observer case. Its eight predicates, 30-second deadline, other ten tests and factory leak assertion are unchanged. This is test hosting, with no production window change; isolated result is verified: 230 passed, zero failed/skipped/expected failures. The original WK observer passed in 4.793s, the leak case in 0.139s, and all eleven WK cases passed; the [preserved original evidence](docs/aster-validation/run25-diagnostic/README.md) records the exact source and hashes. Run 26’s full unit-plan result remains pending. The diagnostic omits the redundant best-effort SDK symbolgraph capture already collected in run 21, without changing a normal release gate. Its full-native, media and extraction jobs are skipped; it builds no IPA.

Full run 26 is active in the independent `candidate26` lane. Its 49 CI contract checks passed; all native outcomes remain pending. The required full unit plan, five preflight, 16 main UI and one isolated download case, exact download bytes and device-package audit are unchanged. That remains 22 UI executions covering 17 unique cases, with no bypass. The isolated diagnostic passes do not establish a full unit/browser/release pass or signed installation.

The AutoFill declaration correction in run 22 restores the main app's entitlement to match upstream and its extension. It is not included in run 20's source and does not certify signed AutoFill. The actual unsigned IPA must still be inspected for embedded entitlements before promising compatibility with a signing tool. [Signing requirements](SIGNING-REQUIREMENTS.md) record this remaining installation work and conditional phone-only routes.

Run 23 additionally hides the unsupported crash-upload control. `DefaultCrashManager.supportsCrashReporting` exposes the existing two-Mozilla-identifier eligibility rule, and Main Settings includes the row only when supported. Aster crash upload remains unsupported; collection defaults and the release-name override behavior are unchanged. The control change is included in current native validation, with results pending.

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

- Complete run 26’s full unit plan, all five preflight cases, all 16 main UI cases, isolated download/integrity and device-package audit. Diagnostics 24/25 passed their isolated selections; run 26’s native results remain pending. Preserve the failed run 22 leak assertion without a waiver; run 23's unit pass applies only to its recorded source. Investigate any recurrence of the earlier fullscreen stall using the new native diagnostics.
- Repeat the iPhone release build/package audit for the corrected delivery source, retaining its exact package hash and provenance. Run 18's completed audit applies only to its recorded source.
- Provide valid Apple signing and matching provisioning for the app and all six extensions before installation. TestFlight also requires Apple Developer/App Store Connect setup; no signing credentials are configured.
- Test the signed application on a physical iPhone 15 Pro Max. The [Arabic device checklist](IPHONE-CHECK-AR.md) records the outstanding physical checks, all explicitly unexecuted.

The existing [native gallery](docs/aster-screenshots/README.md) retains unmodified screenshots from run 38083870485, source `51fe284ead04c0d17b55c51725aa590dd951d031`. Its provenance remains unchanged; run 15's separate gallery preserves its later passing four-case checkpoint.

## Feature and validation limits

Aster is an independent native browser based on Firefox for iOS. It does not implement all Brave features or claim identical parity. Inherited blocking of known fingerprinter URLs is present, but Brave-style canvas/audio fingerprint randomization is not integrated. No dedicated cookie-banner filter or automatic consent-rejection feature is implemented. There is no user-facing strict HTTPS-only mode; inherited automatic HTTPS upgrades are feature-gated on iOS 18.2+ and permit HTTP fallback, with release-channel defaults off and developer/beta defaults on. Real HTTPS upgrade/fallback network behavior remains unverified.

Brave Playlist and a saved-media background-playback library, Brave Sync, Rewards, Wallet, Leo, News and paid VPN services are not implemented. Firefox Account integration remains inherited provider code whose independent identifiers, redirects and end-to-end use are unverified. The Apple-managed default-browser entitlement is not included. Advertising rules are refreshed during builds; this fork does not provide a background advertising-rule updater. Protection depends on the bundled lists and website behavior; no result promises removal of all advertising or tracking.

PiP and AirPlay are enabled in native WebKit configuration, with configuration-level unit assertions; actual PiP/device behavior and AirPlay receivers remain unverified. Simulator decoding of an AAC track is not evidence of audible sound on a physical iPhone. Signed credential extensions, Face ID, protected DRM streams, long-session battery/performance, background audio behavior, complete Arabic translations and accessibility on a physical device require further testing. The latest native run used an iPhone 15 Pro Max simulator and does not certify every supported iOS version. No finite test suite certifies all websites or every browser feature.
