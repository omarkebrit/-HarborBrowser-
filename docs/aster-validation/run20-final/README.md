# Run 20 final native evidence

[Run 20, attempt 1](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39394936415), job `118535214881`, source `273578ee85af23845bf517e76572f02a04a3f678`, completed with a **failed** conclusion. These unmodified files come from compact artifact `12260145582` (31,020,032 bytes). They apply only to this source, not the current delivery candidate.

| Check | Official final result |
| --- | --- |
| Full units | 5,746 passed, 1 failed, 2 skipped |
| Five-case preflight | 3 passed, 2 failed, 0 skipped |
| Main UI | 16 passed, 0 failed, 0 skipped |
| Isolated download | 1 passed, 0 failed, 0 skipped; exact 95-byte SHA-256 verified |
| Original CI device build/package audit | Passed; build 20.1, arm64 iOS device and six extensions |

The download SHA-256 is `fa7f6baddf7671ff0f6f7aa8c03fe987c556a4bc590406da2e8d9542bfdb3dbc`. The original CI audit reports an unsigned IPA of 207,496,026 bytes, SHA-256 `24e29193921ac2ecf3fe7e4862ee7ff8d871befdc96abd3919401e755b0bb167`. IPA publication was skipped because the unit/preflight selections failed. No actual IPA binary was downloaded or independently audited here; only the original CI report is preserved. Signed installation and physical-device behavior remain unverified.

## Passing first-loop rotation in the main execution

The [schedule](AsterAcceptanceTests-attachments/0CA298D5-D18E-4970-8E69-020DB998B7EB.txt) records fresh portrait playback, zero prior wraps and sample age 0.177151 seconds. The [actual resize/offset](AsterAcceptanceTests-attachments/873D3CC6-582D-495A-9AD8-51994D846760.txt) records the first landscape resize 233.201ms after the predicted first loop boundary, within the required −750/+500ms window. Native rotation was requested 397.642ms before that boundary.

The immediate resize sample has 55 frames and a reset fresh-frame baseline. Its momentary `playing:false` is not proof of a stall. The [first landscape capture](AsterAcceptanceTests-attachments/A8E4A7D4-57B5-46EF-A486-AD7339D0C446.png) shows 109 frames/time 4.561; the [two-loop capture](AsterAcceptanceTests-attachments/C103CEFF-78EA-47BA-8121-4B7B35E560F3.png) shows 215 frames/time 1.674, two additional landscape loops and three total wraps. Both show unpaused playback, readyState 4 and no media error. The [exit](AsterAcceptanceTests-attachments/1CC61EFD-DEC4-4369-B7B5-DE77F390470D.png), [native menu](AsterAcceptanceTests-attachments/05462677-EF09-461F-91E5-51B3D36725B6.png) and [final hierarchy](AsterAcceptanceTests-attachments/527F2859-D83B-4FAD-A55A-CF163A368F1E.txt) preserve subsequent interaction.

The earlier preflight execution missed setup after its first wrap and never issued the intended rotation. This later main pass exercised the first boundary. It does not erase that earlier failure or establish a production fix for run 17's stall.

## Actual transport captures

| Transport | Original capture | Decoded frames / media seconds |
| --- | --- | --- |
| MP4 | [View](AsterAcceptanceTests-attachments/869C30C0-BF1D-49D0-9A86-834B7B2C5CB3.png) | 25 / 2.43 |
| HLS | [View](AsterAcceptanceTests-attachments/07AD2198-A469-411F-A4D2-6F21454A1B3C.png) | 22 / 2.50 |
| Iframe | [View](AsterAcceptanceTests-attachments/3414FABD-41CA-4DD5-B71D-69D591C5BA48.png) | 26 / 2.18 |
| Blob | [View](AsterAcceptanceTests-attachments/49DE4BA5-D1B6-4D47-B484-EE8A36BB6DC5.png) | 27 / 2.19 |

All four captures show the expected playing text, unpaused playback, readyState 4, 160×90 video and no media error. These simulator observations do not establish audible sound on an iPhone or compatibility with every website.

## Native excerpt and provenance

The [derived native excerpt](boundary-native-excerpt.txt) preserves complete selected byte-lines from the original main-UI Firefox.1.log. Rotation retained the same fullscreen parent/window. AVPlayer controller lifecycle changes alone did not prove a freeze: the first landscape capture already shows advancing playback before its later controller reappearance. Native playback-state callbacks supplement the frame/time observations; they do not independently prove decoding.

[manifest.json](manifest.json) separates twenty complete unmodified original files from the derived exact-line excerpt, with exact SHA-256/size, owning tests and source-log/filter metadata. The [original main attachment manifest](AsterAcceptanceTests-attachments/manifest.json) also names attachments not copied here; their payloads remain in the original artifact. No large logs or result bundles are copied. This is final evidence for a failed run, not a full-validation pass or an installable release.
