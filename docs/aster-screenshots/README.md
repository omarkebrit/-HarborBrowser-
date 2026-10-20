# Actual Aster simulator captures

These unmodified screenshots come from [GitHub run 38083870485](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38083870485), source `51fe284ead04c0d17b55c51725aa590dd951d031`, on an iPhone 15 Pro Max simulator running iOS 26.5. These are actual test fixtures and UI, not design mockups.

[Run 15 preflight gallery](regression-run15/README.md) preserves five later passing captures with separate provenance. The [run 17 failure evidence](regression-run17/README.md) preserves the subsequent fullscreen stall. The [run 18 preflight checkpoint](regression-run18/README.md) preserves the latest two-loop landscape playback and 25-tab restoration captures with its official four-pass summary.

The current delivery candidate is full native [run 23](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39406335775), source `4557246b64453abb464844aa8ff4358e90107c5b`. Its 45 contract checks and full unit plan passed: 5,747 passed, zero failed and two unchanged upstream runtime skips (5,749 total). The cleaned WK observer case passed in 2.525s; all six corrected Summarize cases passed. Simulator host entitlements passed. Five-case media/session preflight is running; main UI, download and device-package results remain pending. It includes the core fixture/UI corrections and hides the unsupported crash-upload control using existing backend eligibility. Collection defaults remain off.

Full [run 22](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39405042843), source `5174b9a6775c0a0ada40bebf7c309ee300cf1bc5`, continues independently to verify the earlier core corrections; its native results remain pending. Run 20 has completed with one unit and two preflight failures.

Earlier native [run 20](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39394936415), source `273578ee85af23845bf517e76572f02a04a3f678`, completed with its expanded 5/16/1 selection. Its unit summary records 5,746 passes, one WK observer failure and two skips; all six corrected async Summarize tests passed. Its five-case preflight finished with three passes, two failures and zero skips. The boundary-rotation case failed during setup before rotation; the tab case failed its tab 14 hittability check. All 16 main UI cases subsequently passed with zero failures/skips, including MP4/HLS/iframe/blob, strict first-loop rotation and 25-tab restoration. The official isolated download passed 1/0/0 with exact 95-byte verification; the original CI device-package audit for build 20.1 passed. The IPA was not published after the unit/preflight failures.

Targeted [diagnostic run 21](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39402334591), source `92473b44727bb14183775748a0d057ff35a0aae3`, finished with 232 passes and one reproduced synchronous-control failure (zero skips). The async unhosted variant passed; the original case is now made async with the same 30-second deadline and eight checks for full run 22. This comparison is not a full validation pass and produced no IPA. These historical captures do not validate either new source. The [run 20 preflight failure evidence](../aster-validation/run20-preflight/README.md) preserves the new original summary and relevant attachments without changing this gallery. The [run 20 main checkpoint](../aster-validation/run20-main/README.md) preserves its later sixteen-pass summary; no screenshots were exported by that checkpoint. The [final run 20 evidence](../aster-validation/run20-final/README.md) now preserves the original timing/offset and decoded transport/fullscreen images, plus the original CI package audit.

The root gallery's run passed all four preflight cases and 14/15 main cases, failing its immediate post-rotation toolbar assertion. Run 18 later passed its four-case preflight, 14/15 main UI cases, native download/integrity check and unsigned device-package audit; two unit cases failed. Its main failure concerned MP4 status-label hittability despite visible decoded frames. The IPA was withheld. [Final run 18 evidence](../aster-validation/run18/README.md) preserves the official summaries, audit and relevant failure attachments. Existing captures retain their original source provenance and do not establish a playback fix, full current validation, signed installation, every website, complete Arabic translation or physical-device audio. See [the validation report](../../TEST-REPORT.md).

<img src="accessibility-home.png" width="280" alt="Actual Aster homepage at maximum Dynamic Type, with StageServer test tiles">

| Capture | Image |
| --- | --- |
| Light browser chrome at large text | [View](light-browser.png) |
| Dark browser chrome; fixture page stays light | [View](dark-browser.png) |
| Maximum Dynamic Type homepage with StageServer sponsored test tiles | [View](accessibility-home.png) |
| Arabic locale: right-aligned tab tray; translation remains partial | [View](arabic-tab-tray.png) |
| Controlled private-storage fixture | [View](private-storage.png) |
| Decoded MP4 fixture with sound enabled; no device-audio claim | [View](mp4-playback.png) |
| First tab after process relaunch; 25 tabs retained | [View](restored-25-tabs.png) |
| Real portrait fullscreen playback | [View](fullscreen-portrait.png) |
| Real landscape fullscreen playback | [View](fullscreen-landscape.png) |
| Browser after fullscreen exit in the passing preflight invocation | [View](fullscreen-preflight-exit.png) |

[manifest.json](manifest.json) records each original XCTest attachment filename, owning test and SHA-256. The PNG bytes were copied without editing.
