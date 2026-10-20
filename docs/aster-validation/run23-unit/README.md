# Run 23 full unit-plan checkpoint

[Run 23, attempt 1](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39406335775), job `118573067624`, source `4557246b64453abb464844aa8ff4358e90107c5b`, passed its full unit plan. Artifact `12258389074` (210,097,625 bytes) contains the original evidence.

The [official summary](AsterUnitTests-summary.json) records **Passed: 5,747 passed, 0 failed, 2 skipped, 0 expected failures; 5,749 total**. The two skips are the existing upstream runtime cases `TabEventHandlerTests.testBlankPopupURL` (AppDelegate setup dependency) and `TestHistory.testRandomThreading` (FXIOS-12339).

The cleaned original `WKEngineWebViewTests.testLoad_callsObservers` passed in 2.525 seconds, with no temporary diagnostic or window wrapper. All six corrected async Summarize cases and their suite passed; `test_summarize_withNotEnoughStartingWords` passed in 0.153 seconds. The source retains the original checks and deadlines.

The [derived excerpt](unit-corrections-and-skips-excerpt.txt) preserves 13 complete, byte-identical lines: the WK case start/pass, six corrected Summarize case passes, suite pass, and both skip reasons/results. It is a subset rather than a complete original log. [manifest.json](manifest.json) separates the three unmodified complete originals from the derived file and records its exact matching rules, full source-log SHA-256/size and excerpt hash/size.

The [recorded source](source-commit.txt) and [toolchain](toolchain.txt) are unchanged. At this checkpoint, media/session preflight was running and main UI, download and device-package results remained pending. This is not a full-validation pass, a published IPA, signed installation or physical-device result. No large logs or result bundles are copied here.
