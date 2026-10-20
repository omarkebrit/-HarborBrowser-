# Run 18 final validation evidence

[Native run 18, attempt 1](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39379658275), source `7788245534fc23c00a93fb8375c83ebce8703a1e`, **failed**. This small set preserves unmodified files from its original artifact `12251425178`. [Recovery run 19](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39394322518), source `7613a000119a4877578a7df070d827e27c8fb954`, successfully extracted them into artifact `12251460795`; its native job was skipped. That extraction is not a new native validation pass.

| Check | Official result |
| --- | --- |
| Full unit plan | 5,745 passed, 2 failed, 2 skipped; 5,749 total |
| Four-case preflight | 4 passed, 0 failed, 0 skipped |
| Main UI selection | 14 passed, 1 failed, 0 skipped |
| Isolated native download | 1 passed, 0 failed, 0 skipped; exact 95-byte SHA-256 verified |
| Unsigned iPhone release package | Build and actual-package audit passed; build `18.1`, arm64 iOS device, six extensions |

Unit failures were `SummarizeViewModelTests/test_summarize_withNotEnoughStartingWords()` (0.5-second callback expectation) and `WKEngineWebViewTests/testLoad_callsObservers()` (30-second progress/content-size expectations). `SearchTests.testSuggestClient` passed in 0.709 seconds. The [preserved crash](AsterUnitTests-attachments/EFE15380-5019-49CF-AE5F-D9EFCDE4FA35.ips) has capture time 06:45:45.2127 UTC and a late Summarize callback stack. Although the attachment export associates it with the WK test, it is not evidence of a WK-test crash.

The main failure occurred while determining the first MP4 status label's hittability in `testMP4HLSIframeAndBlobPlayRealAudioAndVideo()`. The [original screenshot](AsterAcceptanceTests-attachments/F1E23B6D-0560-4B4F-99FE-374F11718523.png) shows decoded playback (67 observed frames, media time 5.64, paused false, readyState 4, no error). The [failure hierarchy](AsterAcceptanceTests-attachments/A04A0037-E663-41C7-8F9E-744BE063B7F1.txt) and [final hierarchy](AsterAcceptanceTests-attachments/FC0438AD-2F50-460B-8EA8-BB0909403D50.txt) are preserved. Later HLS, iframe and blob iterations in that case were not executed; the separate fullscreen case passed.

The audited IPA was 207,494,746 bytes, SHA-256 `e1a064a96f3027356d0be1ee0abf4911eb54438336a3f7e9eca2847d95700274`. It was **not published**, because required tests failed. Only its audit report is retained here, not the IPA. Apple signing, signed installation and physical-device testing remain unverified.

[manifest.json](manifest.json) records every copied file's exact SHA-256, byte count, source and recovery provenance, attachment ownership and the crash-association correction. The four original summaries, [package audit](device-ipa-audit.json), [download integrity](download-integrity.json), [recorded source](source-commit.txt) and [toolchain](toolchain.txt) remain byte-for-byte unchanged. These results apply to run 18's recorded source; the next candidate's fixes and expanded 5/16/1 selection are not native-verified.
