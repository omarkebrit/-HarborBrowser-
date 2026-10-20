# Actual Aster simulator captures

These unmodified screenshots come from [GitHub run 38083870485](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38083870485), source `51fe284ead04c0d17b55c51725aa590dd951d031`, on an iPhone 15 Pro Max simulator running iOS 26.5. These are actual test fixtures and UI, not design mockups.

[Run 15 preflight gallery](regression-run15/README.md) contains five newer verified fullscreen and tab-restoration captures with separate provenance. The [run 17 failure evidence](regression-run17/README.md) preserves unmodified portrait/landscape captures and the failed preflight summary.

In the depicted run, the preflight passed all four cases and the main selection passed 14/15; its immediate post-rotation toolbar assertion failed. Run 15's separate gallery retains its passing four-case checkpoint. [Run 17](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38410673448), source `6d8eec264d4eaafea4eaed6bd2ff919e0005f7f8`, later passed popup playback, restrictive autoplay and 25-tab creation/restoration, but its fullscreen video froze after rotation at a loop boundary. The diagnostic candidate is launched in [run 18](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39379658275), attempt 1, source `7788245534fc23c00a93fb8375c83ebce8703a1e`; its results remain unverified. These images retain their original source provenance and do not certify the current source, signed installation, every website, complete Arabic translation or physical-device audio. See [the validation report](../../TEST-REPORT.md).

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
