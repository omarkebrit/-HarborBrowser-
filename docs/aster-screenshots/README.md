# Actual Aster simulator captures

These unmodified screenshots come from [GitHub run 38083870485](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38083870485), source `51fe284ead04c0d17b55c51725aa590dd951d031`, on an iPhone 15 Pro Max simulator running iOS 26.5. These are actual test fixtures and UI, not design mockups.

[Run 15 preflight gallery](regression-run15/README.md) preserves five later passing captures with separate provenance. The [run 17 failure evidence](regression-run17/README.md) preserves the subsequent fullscreen stall. The [run 18 preflight checkpoint](regression-run18/README.md) preserves the latest two-loop landscape playback and 25-tab restoration captures with its official four-pass summary.

Full [run 23](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39406335775), source `4557246b64453abb464844aa8ff4358e90107c5b`, passed units 5,747/0 failed/2 upstream skips but failed preflight 3/2, blocking IPA publication; main UI finished 15 passed/one failed, download/byte-verification steps passed and device outcomes remain pending. Parallel [run 22](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39405042843), source `5174b9a6775c0a0ada40bebf7c309ee300cf1bc5`, recorded units 5,745/2 failed/2 skipped.

Media-only [diagnostic 24](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39414241881), source `e0f89e5f8ce34e6faa230dac404b5a1434712486`, remains in progress. Isolated-WebEngine [diagnostic 25](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39414543028), source `1617b9a76839208c5f2ac533a646226929491787`, passed 230/0 failed/0 skipped/0 expected failures; the original window observer passed in 4.793s and all eleven WK cases passed. Neither publishes an IPA or replaces full native validation; the next full candidate has not started. See [TEST-REPORT.md](../../TEST-REPORT.md) for source-bound evidence.

Additional source-bound sets preserve [run 15's checkpoint](regression-run15/README.md), [run 17's failure](regression-run17/README.md), [run 18's checkpoint](regression-run18/README.md), [run 20's final media evidence](../aster-validation/run20-final/README.md) and [run 23's preflight failure](../aster-validation/run23-preflight/README.md). The root images and manifest retain their original source provenance; signed-device/audio/translation or universal-website claims are not established. See [TEST-REPORT.md](../../TEST-REPORT.md).

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
