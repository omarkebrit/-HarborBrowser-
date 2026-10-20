# Actual Aster simulator captures

These unmodified screenshots come from [GitHub run 38083870485](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38083870485), source `51fe284ead04c0d17b55c51725aa590dd951d031`, on an iPhone 15 Pro Max simulator running iOS 26.5. These are actual test fixtures and UI, not design mockups.

[Run 15 preflight gallery](regression-run15/README.md) preserves five later passing captures with separate provenance. The [run 17 failure evidence](regression-run17/README.md) preserves the subsequent fullscreen stall. The [run 18 preflight checkpoint](regression-run18/README.md) preserves the latest two-loop landscape playback and 25-tab restoration captures with its official four-pass summary.

Current native [run 20](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39394936415), source `273578ee85af23845bf517e76572f02a04a3f678`, is in progress with its expanded 5/16/1 selection. Its unit summary records 5,746 passes, one WK observer failure and two skips; all six corrected async Summarize tests passed. Its five-case preflight finished with three passes, two failures and zero skips. The boundary-rotation case failed during setup before rotation; the tab case failed its tab 14 hittability check. Main UI is running and later native outcomes remain pending.

Targeted [diagnostic run 21](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39402334591), source `92473b44727bb14183775748a0d057ff35a0aae3`, was dispatched to investigate four temporary observer-test variants. Its results are pending; it does not run the full validation pipeline or produce an IPA. Full run 20 continues independently. These historical captures do not validate either new source. The [run 20 preflight failure evidence](../aster-validation/run20-preflight/README.md) preserves the new original summary and relevant attachments without changing this gallery.

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
