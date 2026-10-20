# Run 21 WebEngine diagnostic comparison

[Diagnostic run 21](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39402334591), source `92473b44727bb14183775748a0d057ff35a0aae3`, isolated the WebEngine package and four temporary observer-test variants. Job `118559853701` produced artifact `12255849410` (60,302,698 bytes). The full native-validation job was skipped; no IPA was built or published.

The [official summary](WebEngineDiagnostics-summary.json) records **232 passed, 1 failed, 0 skipped, 0 expected failures, 233 total**. The original synchronous unhosted control reproduced its failure; it was not waived or marked as an XCTest expected failure. This diagnostic is not a full unit-plan/browser/release pass.

| Variant | Observed result |
| --- | --- |
| [Synchronous unhosted control](WebEngineDiagnostics-attachments/991551F1-47A6-4485-A0FE-2D4D35961F0F.txt) | Failed after 32.489s; progress 0.1, without recorded navigation didStart/didCommit/didFinish |
| [Async unhosted](WebEngineDiagnostics-attachments/A00367E8-7DF3-4BC4-8E5E-4F1AEAFE2978.txt) | Passed in 0.963s; didStart/didCommit/didFinish, progress 1, title Test Page, content 980×1960 |
| [Async window-hosted](WebEngineDiagnostics-attachments/50587F29-16EC-48FF-BC3B-F2DC6BBA3048.txt) | Passed |
| [Synchronous window-hosted](WebEngineDiagnostics-attachments/A5633A43-4673-4B9A-8CA7-259377FF74FB.txt) | Passed |

`applicationState` was nil in all four diagnostic attachments. The async unhosted result supports the minimal test-fixture correction: make the original observer test async and await its same 30-second expectations, retaining all eight checks. The next full candidate removes the temporary variants and does not introduce a production or window-hosting change. Its full native outcome remains pending.

[manifest.json](manifest.json) records exact hashes, sizes, source/artifact identity and owning cases for the nine complete original files. The [scope](diagnostic-scope.txt), [source](source-commit.txt), [toolchain](toolchain.txt) and [original attachment manifest](WebEngineDiagnostics-attachments/manifest.json) remain unmodified. No separate issue attachment was exported; the failure text is retained in the official summary. No result bundles or SDK symbol graphs are copied here.
