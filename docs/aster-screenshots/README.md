# Actual Aster simulator captures

These unmodified screenshots come from [GitHub run 38083870485](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38083870485), source `51fe284ead04c0d17b55c51725aa590dd951d031`, on an iPhone 15 Pro Max simulator running iOS 26.5. These are actual test fixtures and UI, not design mockups.

[Run 15 preflight gallery](regression-run15/README.md) preserves five later passing captures with separate provenance. The [run 17 failure evidence](regression-run17/README.md) preserves the subsequent fullscreen stall. The [run 18 preflight checkpoint](regression-run18/README.md) preserves the latest two-loop landscape playback and 25-tab restoration captures with its official four-pass summary.

The root gallery's run passed all four preflight cases and 14/15 main cases, failing its immediate post-rotation toolbar assertion. Run 18's preflight passed all four cases, but its full unit stage failed; the main UI stage also failed, with case-level results pending. The isolated native download and exact 95-byte integrity check passed; device build/audit results remain pending. Its read-only diagnostics do not establish a fix for run 17's stall. These images retain their original source provenance and do not certify a full current validation, signed installation, every website, complete Arabic translation or physical-device audio. See [the validation report](../../TEST-REPORT.md).

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
