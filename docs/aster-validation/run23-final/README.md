# Run 23 final evidence

These original files come from [run 23](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39406335775), attempt 1, job `118573067624`, source `4557246b64453abb464844aa8ff4358e90107c5b`. The final compact artifact is `12263454989`, `Aster-compact-validation-evidence-attempt-1`: 28,700,577 ZIP bytes, SHA-256 `55a9ecaa83a3b45bc587a9d4e3a3f98e0eb817a0d38ea0cc224f306580a2df78`. ZIP CRC and all 202 compact-manifest file sizes/hashes (88,482,502 bytes) were verified. The source marker matches that exact commit.

| Official final selection | Passed | Failed | Skipped |
| --- | ---: | ---: | ---: |
| [Unit](AsterUnitTests-summary.json) | 5747 | 0 | 2 |
| [Preflight regression](AsterRegressionTests-summary.json) | 3 | 2 | 0 |
| [MAIN acceptance](AsterAcceptanceTests-summary.json) | 15 | 1 | 0 |
| [Download](AsterDownloadTests-summary.json) | 1 | 0 | 0 |

These are the official top-level summary counts; expanded parameterized device counts differ for the unit selection. The whole validation did not pass. MAIN failed only `testElementFullscreenKeepsPlayingWhenFirstLoopBoundaryMeetsRotation`, with `Missing rendered page text: Fullscreen first-loop boundary rotation observed`. Preflight separately failed that observer assertion and the tab 18 viewport assertion in `testTwentyFiveTabsSurviveProcessRelaunch`; those are separate executions and must retain their individual results.

## MAIN boundary evidence

The [original schedule](AsterAcceptanceTests-attachments/B13C8A3A-25E4-443C-AA79-5C08379A62C2.txt) records a fresh portrait clock at 1.622046997 seconds, playback true, zero prior natural wraps and sample age 0.181310177 seconds. It predicts the first six-second boundary at epoch **1792495100240.953 ms** (11:18:20.240953 UTC) and records the native rotation request at **1792495099843.142 ms** (11:18:19.843142 UTC), **397.811 ms before** that prediction.

MAIN's own final hierarchies prove advancing decoded landscape playback:

| Original hierarchy | Clock epoch ms | Media seconds | Frames | Landscape phase loops | Global wraps |
| --- | ---: | ---: | ---: | ---: | ---: |
| [695DBF54-88D5-4CA5-9946-FBD0EF3F30FB.txt](AsterAcceptanceTests-attachments/695DBF54-88D5-4CA5-9946-FBD0EF3F30FB.txt) | 1792495116057 | 2.933532758 | 221 | 2 | 3 |
| [AE50918D-F92C-41D4-9A51-A327CACE1541.txt](AsterAcceptanceTests-attachments/AE50918D-F92C-41D4-9A51-A327CACE1541.txt) | 1792495116560 | 3.436439925 | 227 | 2 | 3 |

The media clock advances by about 0.503 seconds and the frame counter increases by six. Both show unpaused playback, ready state 4, no error, visible fullscreen stage 814x348, and `Fullscreen loop playback verified in landscape`. The final original screenshot [4CF79E45-D292-4584-8626-C24D6A51CD1F.png](AsterAcceptanceTests-attachments/4CF79E45-D292-4584-8626-C24D6A51CD1F.png) visibly shows the decoded colored pattern and an intermediate 225-frame sample. This MAIN evidence rules out a persistent zero-frame freeze at the failure captures independently of the earlier preflight evidence.

The same captures still show `Waiting for first-loop boundary rotation` and `Aster rotation observation null`. The expected observed label was never produced. No actual first landscape layout epoch was latched, so the strict -750/+500 ms boundary assertion **was not established and the test remains failed**. The compact MAIN evidence does not itself capture the precise intermediate stage geometry at the missing callback. The preflight's separately reviewed window-event-before-layout sequence must not be presented as a directly observed MAIN geometry sequence. These final snapshots also do not establish uninterrupted playback throughout the entire rotation or a production fix for the historical run 17 stall.

## Native timeline and package limits

The separately identified [derived native excerpt](derived/boundary-native-excerpt.txt) retains unchanged selected lines from `session-diagnostics/main-ui/app/Library/Caches/Logs/Firefox.1.log`. [manifest.json](manifest.json) records the full source log's bytes/SHA-256, exact filter, excerpt bytes/SHA-256 and line count. It is not the complete original log.

MAIN's native rotation begins at **11:18:19.943 UTC** and completes at **11:18:20.292**, retaining the same fullscreen parent/window and fullscreen state 2. The AVPlayer controller disappears at 11:18:20.795 and reappears at 11:18:26.887. Fullscreen exits at 11:18:37.717-37.878, restoring the browser host. Native media-state queries supplement the decoded-frame evidence; controller lifecycle or `.playing` state alone does not prove rendering progress. Native rotation-completion time is not a substitute for the missing actual stage-layout epoch.

The original CI device audit reports **Passed** for unsigned build **23.1**, arm64 iOS, minimum iOS 15.0, built with iPhoneOS SDK 26.5. It records an IPA size of **207,499,582 bytes** and SHA-256 `2d31a076651fb1b547a114dd668e7f2e5cfe86e02092b6071f9cedcaba661536`. The actual IPA was withheld by failed required checks and was not independently downloaded or inspected here. Apple signing/provisioning is still required. The original download integrity record reports the 95-byte `aster-payload.txt` SHA-256 `fa7f6baddf7671ff0f6f7aa8c03fe987c556a4bc590406da2e8d9542bfdb3dbc`. Toolchain evidence records Xcode 26.5 (17F42); the summaries identify iPhone 15 Pro Max, iOS 26.5 (23F77), Simulator. These observations do not certify physical-device sound, signed installation or every website.

[manifest.json](manifest.json) names 13 byte-identical original files and their exact sizes/hashes. It also records all four official summaries, the [CI package audit](device-ipa-audit.json), [download integrity](download-integrity.json), [source](source-commit.txt) and [toolchain](toolchain.txt). The [complete original MAIN attachment index](AsterAcceptanceTests-attachments/manifest.json) is preserved and references payloads not copied into this smaller proof set. The native excerpt is separately identified derived material; this README is analysis. Full run 26 remains a separate delivery candidate, with its own normal validation gates.
