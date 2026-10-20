# Actual Aster simulator captures

These unmodified screenshots come from [GitHub run 38083870485](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38083870485), source `51fe284ead04c0d17b55c51725aa590dd951d031`, on an iPhone 15 Pro Max simulator running iOS 26.5. These are actual test fixtures and UI, not design mockups.

[Run 15 preflight gallery](regression-run15/README.md) preserves five later passing captures with separate provenance. The [run 17 failure evidence](regression-run17/README.md) preserves the subsequent fullscreen stall. The [run 18 preflight checkpoint](regression-run18/README.md) preserves that run’s two-loop landscape playback and 25-tab restoration captures with its official four-pass summary.

**No downloadable release or completed full-validation pass is available.** Full [run 26](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39420482530), source `82dd060ead28e7e0170218a342fbcb991bbeef58`, started on 20 October at 12:12:25 UTC. Its 49 CI contract checks passed (24 Node and 25 Python); native units, five preflight cases, 16 main UI cases, isolated download/integrity and device build/package audit remain pending.

Media-only [diagnostic 24](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39414241881), source `e0f89e5f8ce34e6faa230dac404b5a1434712486`, passed both selected cases with zero failures, skips or expected failures. Isolated-WebEngine [diagnostic 25](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39414543028), source `1617b9a76839208c5f2ac533a646226929491787`, passed 230/0 failed/0 skipped/0 expected failures. Neither produces an IPA or replaces run 26’s full validation. See [TEST-REPORT.md](../../TEST-REPORT.md) for source-bound evidence.

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
