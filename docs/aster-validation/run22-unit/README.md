# Run 22 unit failure checkpoint

[Run 22, attempt 1](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39405042843), job `118568814602`, source `5174b9a6775c0a0ada40bebf7c309ee300cf1bc5`, recorded **Failed: 5,745 passed, 2 failed, 2 skipped, 0 expected failures; 5,749 total**. These complete unmodified files come from artifact `12260347642` (372,163,039 bytes).

The [official summary](AsterUnitTests-summary.json) names two failures:

- `WKEngineWebViewTests.testLoad_callsObservers`: the async original case exceeded its 30-second progress/content-size expectations. The accompanying run log reports an unresponsive WebProcess; it does not provide a final progress probe value, so no final progress value is inferred here.
- `TabWebViewTests.testBasicTabWebView_doesntLeak`: its inherited weak-reference teardown assertion still found the test WebView. The retaining owner is unknown. The unchanged test passed in runs 18, 20 and 23; no waiver or production retention fix is established.

The six corrected async Summarize cases passed. A visible-window fixture adjustment for the WK test is awaiting isolated diagnostic verification. It keeps all eight predicates and the 30-second deadline; it does not change production window behavior. This checkpoint is not a full validation pass or an installable release.

[manifest.json](manifest.json) records exact SHA-256/size and source/artifact provenance for the [summary](AsterUnitTests-summary.json), [recorded source](source-commit.txt) and [toolchain](toolchain.txt). No large logs or result bundles are copied here. Further details remain in the [validation report](../../../TEST-REPORT.md).
