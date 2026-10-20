# Run 23 preflight failure evidence

[Run 23, attempt 1](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39406335775), job `118573067624`, source `4557246b64453abb464844aa8ff4358e90107c5b`, recorded **3 passed, 2 failed, 0 skipped, 0 expected failures** in its five-case preflight. These complete unmodified files come from artifact `12260576743` (242,570,011 bytes). The full unit plan separately passed 5,747/0 failed/2 skipped; main UI was running at this checkpoint and download/device results remained pending. The preflight failures block IPA publication.

## Boundary observation failure with advancing playback

The case failed on missing text `Fullscreen first-loop boundary rotation observed`. The [schedule](AsterRegressionTests-attachments/14F9C954-4175-4D04-A0BB-BD61530B9FCD.txt) records fresh portrait playback, zero prior wraps and a request 332.577ms before the predicted first boundary. The [final hierarchy](AsterRegressionTests-attachments/E8CC0BB6-A0C3-419C-B899-820F811D4EBD.txt) shows a landscape window/stage, playing true, media time 4.837, 258 frames, two landscape loops and three total wraps, readyState 4 and no error. Yet `Aster rotation observation` remains null.

The [final screenshot](AsterRegressionTests-attachments/C519D9F7-E610-431F-93BB-9BA2C9F68B20.png) independently shows advancing landscape media at 253 frames/time 4.426 with the loop-verification label. This is a missing geometry-observation latch, not evidence of a persistent playback freeze. The actual first-landscape epoch was not recorded, so the required first-boundary timing assertion did not pass. A stage-geometry observation correction remains under review; no implementation or native pass is claimed here.

## Tab 18 readiness failure

The case failed its 10-second geometry wait for `Local tab 18 ready`. The test was performing three sequential frame-snapshot lookups. Its [text debug output](AsterRegressionTests-attachments/0E722235-A107-4FA2-AE69-4B659576116E.txt) records the label's finite 16/124/147/24 frame but unavailable/nonfinite ancestor frames. The later [whole-app hierarchy](AsterRegressionTests-attachments/355865DD-D0A1-4526-B0BF-BFCC063AECED.txt) and [screenshot](AsterRegressionTests-attachments/11279F89-5351-4F28-9701-72C6523DE3FF.png) show the page inside the native viewport and tab count 18. The case did not complete 25-tab creation/restoration. A one-snapshot helper correction is prepared locally and remains native-unverified.

[manifest.json](manifest.json) records exact SHA-256/size, source identity, owning tests and original attachment names for ten complete original files. The [original attachment manifest](AsterRegressionTests-attachments/manifest.json), [source](source-commit.txt), [toolchain](toolchain.txt) and [official summary](AsterRegressionTests-summary.json) remain unchanged. No raw logs, videos or result bundles are copied. This is failed-checkpoint evidence, not a full browser pass, published IPA or physical-device result.
