# Run 25 isolated WebEngine validation

[Run 25, attempt 1](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39414543028), job `118600244217`, source `1617b9a76839208c5f2ac533a646226929491787`, passed the isolated WebEngine package tests. Artifact `12261872697` contains the original evidence (530,137 bytes); its SHA-256 matches GitHub's digest and all 508 ZIP entries passed CRC verification.

The [official summary](WebEngineDiagnostics-summary.json) records **230 passed, 0 failed, 0 skipped, 0 expected failures; 230 total** on an arm64 iPhone 15 Pro Max simulator running iOS 26.5 (23F77), built with Xcode 26.5 (17F42).

The original `WKEngineWebViewTests.testLoad_callsObservers` passed in 4.793 seconds with its retained visible-window fixture, eight existing KVO predicates and 30-second deadline. `testNoLeaks` passed in 0.139 seconds, and all 11 cases in that class passed. The source contains no temporary diagnostic variants or probes. This isolated result does not establish the cause of earlier WebKit stalls or guarantee repeatability in the full unit plan.

[manifest.json](manifest.json) records the archive identity, verification, official counts and exact hashes of the four complete original files: [summary](WebEngineDiagnostics-summary.json), [source](source-commit.txt), [toolchain](toolchain.txt) and [scope](diagnostic-scope.txt). The separately identified [derived excerpt](wk-observer-and-leak-excerpt.txt) contains seven complete, unchanged source-log lines for the observer case, leak case, class result and overall test success. Its origin log's full size and SHA-256 are recorded; the excerpt is a subset of that log.

This is isolated package validation. The full native-validation job was skipped, and no IPA was built or published. It is not a full unit-plan, browser-wide, signed-installation or physical-device result. No full logs or result bundles are copied here.
