# Run 20 main UI checkpoint

[Run 20, attempt 1](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39394936415), job `118535214881`, source `273578ee85af23845bf517e76572f02a04a3f678`, completed its main selection with **16 passed, 0 failed, 0 skipped, 0 expected failures**. These three unmodified original files come from checkpoint artifact `12258185452` (509,396 bytes), on the iPhone 15 Pro Max simulator with iOS 26.5 (23F77) and Xcode 26.5 (17F42).

The checkpoint acceptance log confirms all four MP4, HLS, iframe and blob iterations actually executed, each with a decoded-video attachment, and their combined case passed in 65.917 seconds. The strict first-loop-boundary rotation case passed in 74.030 seconds, ordinary rotation/exit passed in 61.829 seconds and 25-tab creation/restoration passed in 597.062 seconds. All other selected main cases passed too.

The boundary case recorded schedule, actual-resize and offset attachments in its result bundle. Their payloads and screenshots were not exported by this checkpoint; exact offset/image review awaits the complete native evidence. This records a pass in this main execution. It does not erase the earlier three-pass/two-failure preflight, including its setup miss, or establish a production fix for run 17's stall.

Run 20's unit and preflight failures still prevent a full-validation pass and IPA publication. At this checkpoint the isolated download was running and device-package outcomes were pending. The current delivery candidate is recorded separately in the main validation report.

[manifest.json](manifest.json) preserves exact SHA-256/size/source/artifact identity for the [official summary](AsterAcceptanceTests-summary.json), [source](source-commit.txt) and [toolchain](toolchain.txt). It also records the hash/size of the reviewed acceptance log, without copying it. No screenshots or result bundles are included here.
