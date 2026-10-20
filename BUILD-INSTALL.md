# Building and installing Aster

## GitHub build

**No downloadable release or completed full-validation pass is available.** Full [run 23](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39406335775) passed units 5,747/0 failed/2 upstream skips but failed preflight 3/2, blocking its IPA; its main UI is running. Parallel [run 22](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39405042843) recorded units 5,745/2 failed/2 skipped.

Media-only [diagnostic 24](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39414241881), source `e0f89e5f8ce34e6faa230dac404b5a1434712486`, and WebEngine-only [diagnostic 25](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39414543028), source `1617b9a76839208c5f2ac533a646226929491787`, are running. They test fixture corrections and produce no IPA; the next full candidate has not started. See [TEST-REPORT.md](TEST-REPORT.md) for source-bound results, diagnostics and permanent evidence.

1. Open [Aster's workflow runs](https://github.com/omarkebrit/-HarborBrowser-/actions/workflows/aster-ios.yml) and use the exact full-validation run identified in [TEST-REPORT.md](TEST-REPORT.md) after all required checks pass. No successful delivery run is available yet; diagnostic runs 24/25 contain no IPA. The full native job has a 180-minute budget.
2. Wait for all required checks, device build and actual-package audit to pass for that source. Older screenshots and partial evidence do not establish delivery readiness.
3. After the full run succeeds, sign in to GitHub and download **Aster-iPhone-UNSIGNED-needs-signing-attempt-1** from **Artifacts**.
4. Extract `Aster-UNSIGNED-needs-signing.ipa` from the ZIP in the iPhone Files app.

Artifact names end in `attempt-N`, matching the GitHub run attempt. A retry changes the suffix; select the artifact belonging to the successful attempt. Full native evidence is named `Aster-native-validation-evidence-attempt-N`, and generated filter evidence is `aster-ad-filters-attempt-N`. Logs, attachments and artifacts are retained for seven days.

The workflow uses the standard `macos-26` runner and Xcode 26.5, pinned Swift package revisions, a verified Nimbus generator and a verified advertising converter. [GitHub documents standard hosted-runner usage as free for public repositories](https://docs.github.com/en/billing/concepts/product-billing/github-actions). Public compilation does not provide Apple signing or signed installation.

The workflow currently exists only on `feat/aster-browser`, while the repository's default branch remains `main`. GitHub requires a `workflow_dispatch` file on the default branch before offering manual **Run workflow** execution, so that button may be unavailable. The registered branch workflow was successfully dispatched through the GitHub API/CLI for runs 21–23; for example, `gh workflow run aster-ios.yml --ref feat/aster-browser -f validation_lane=manual`. This observed API route is separate from availability of the browser button. Branch pushes without a skip-CI marker also trigger this workflow. If a completed attempt needs another retry, **Re-run jobs → Re-run all jobs** is available within 30 days with repository write access and reuses the original run's source commit. No default-branch merge is required to rerun the existing run or trigger a branch push. See [GitHub's manual-workflow requirements](https://docs.github.com/en/actions/how-tos/managing-workflow-runs-and-deployments/managing-workflow-runs/manually-running-a-workflow) and [rerun instructions](https://docs.github.com/en/actions/how-tos/managing-workflow-runs-and-deployments/managing-workflow-runs/re-running-workflows-and-jobs).

## Installing on an iPhone

An unsigned IPA cannot be installed directly by tapping it in Safari. A signing service must sign the app and its embedded extensions with a valid certificate and matching provisioning profiles. A multi-extension app may need separate bundle identifiers and app-group entitlements in those profiles. Do not assume a generic one-file signing tool supports this automatically.

For a supported TestFlight route, use an Apple Developer membership and App Store Connect, register the app and extension identifiers, configure certificates/profiles, then add a signed archive/export workflow. This repository has no Apple credentials and does not upload to TestFlight.

With only an iPhone, installation still depends on a compatible signing route. AltStore documents on-device Classic 2.3 setup through PAL on iOS 27 in eligible regions; Aster compatibility remains unverified. [SIGNING-REQUIREMENTS.md](SIGNING-REQUIREMENTS.md) covers that conditional free route, account limits and the actual-IPA entitlement checks still needed. TestFlight testers do not need their own paid developer membership, although a legitimate developer team must supply the signed upload.

Apple lists the AutoFill-provider capability for program members, with no support mark for free developer accounts. A generic free AltStore route therefore does not establish free provisioning of complete Aster with all six extensions and system AutoFill.

The application identifier is `com.omarkebrit.aster`; the app group is `group.com.omarkebrit.aster`. The main application does not request Mozilla's managed default-browser entitlement. Additional managed capabilities require Apple's approval and appropriate provisioning.

The retained package has these seven profile assignments when all extensions are included:

| Component | Bundle identifier |
| --- | --- |
| Main app | `com.omarkebrit.aster` |
| Widgets | `com.omarkebrit.aster.WidgetKit` |
| Notification service | `com.omarkebrit.aster.NotificationService` |
| Credential provider | `com.omarkebrit.aster.CredentialProvider` |
| Stickers | `com.omarkebrit.aster.Sticker` |
| Action extension | `com.omarkebrit.aster.ActionExtension` |
| Share extension | `com.omarkebrit.aster.ShareTo` |

Use the same legitimate Apple team and certificate for the app and extensions. App-group targets need the shared registered group; keychain access needs the real App Identifier Prefix. Both the main app and credential-provider extension need the autofill capability. Embedded frameworks and executable code also need correct signing. Ad hoc delivery additionally needs the iPhone's registered UDID and a supported installation route. The current unsigned workflow supplies none of these credentials or signed exports.

## Local native development

On a Mac with Xcode 26.5, Node 24 and Python 3.12:

```sh
bash scripts/aster-ci-prepare.sh
open firefox-ios/Client.xcodeproj
```

Use the existing `Fennec` scheme with `Debug` for simulator work. The production device configuration is named `Firefox` in the upstream project. Internal module, target and scheme names remain upstream names; the delivered application is Aster.

The original support material is preserved in `README.upstream.md` and `docs/`. Upstream service credentials and branding permissions are not transferred by this fork.
