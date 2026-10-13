# Building and installing Aster

## GitHub build

The repository is public. Aster's source is on [`feat/aster-browser`](https://github.com/omarkebrit/-HarborBrowser-/tree/feat/aster-browser); the earlier Harbor branches and history are also public. [Run 38377770464](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38377770464), run number 11, attempt 1, is in progress for source `d0a980ec3313bccb40bd31e4863bd9d5b92ac418`. No production IPA is available yet.

1. Open the current run and monitor its native job. The 180-minute job budget accommodates native compilation and the required test stages. In the previous attempt, initial native build/launch took about 18 minutes before the four test cases began; the cases then took about 11 minutes.
2. Wait for all required checks and the device build to pass. The workflow saves **Aster-regression-validation-evidence-attempt-1** after all four preflight cases pass, before unit tests. That checkpoint proves the selected regressions; it is not an installable app or a complete validation result.
3. After the full run succeeds, sign in to GitHub and download **Aster-iPhone-UNSIGNED-needs-signing-attempt-1** from **Artifacts**.
4. Extract `Aster-UNSIGNED-needs-signing.ipa` from the ZIP in the iPhone Files app.

Artifact names end in `attempt-N`, matching the GitHub run attempt. A retry changes the suffix; select the artifact belonging to the successful attempt. Full native evidence is named `Aster-native-validation-evidence-attempt-N`, and generated filter evidence is `aster-ad-filters-attempt-N`. Logs, attachments and artifacts are retained for seven days.

The workflow uses the standard `macos-26` runner and Xcode 26.5, pinned Swift package revisions, a verified Nimbus generator and a verified advertising converter. [GitHub documents standard hosted-runner usage as free for public repositories](https://docs.github.com/en/billing/concepts/product-billing/github-actions). Public compilation does not provide Apple signing or signed installation.

The workflow currently exists only on `feat/aster-browser`, while the repository's default branch remains `main`. GitHub requires a `workflow_dispatch` file on the default branch before offering manual **Run workflow** execution, so that button may be unavailable. Branch pushes without a skip-CI marker also trigger this workflow. If a completed attempt needs another retry, **Re-run jobs → Re-run all jobs** is available within 30 days with repository write access and reuses the original run's source commit. No default-branch merge is required to rerun the existing run or trigger a branch push. See [GitHub's manual-workflow requirements](https://docs.github.com/en/actions/how-tos/managing-workflow-runs-and-deployments/managing-workflow-runs/manually-running-a-workflow) and [rerun instructions](https://docs.github.com/en/actions/how-tos/managing-workflow-runs-and-deployments/managing-workflow-runs/re-running-workflows-and-jobs).

## Installing on an iPhone

An unsigned IPA cannot be installed directly by tapping it in Safari. A signing service must sign the app and its embedded extensions with a valid certificate and matching provisioning profiles. A multi-extension app may need separate bundle identifiers and app-group entitlements in those profiles. Do not assume a generic one-file signing tool supports this automatically.

For a supported TestFlight route, use an Apple Developer membership and App Store Connect, register the app and extension identifiers, configure certificates/profiles, then add a signed archive/export workflow. This repository has no Apple credentials and does not upload to TestFlight.

With only an iPhone and no Apple Developer setup or compatible signing service, GitHub can deliver the compiled file but cannot provide a signed installation. This limit comes from iOS installation rules.

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

Use the same legitimate Apple team and certificate for the app and extensions. App-group targets need the shared registered group; keychain access needs the real App Identifier Prefix. The credential-provider extension needs the autofill capability. Embedded frameworks and executable code also need correct signing. Ad hoc delivery additionally needs the iPhone's registered UDID and a supported installation route. The current unsigned workflow supplies none of these credentials or signed exports.

## Local native development

On a Mac with Xcode 26.5, Node 24 and Python 3.12:

```sh
bash scripts/aster-ci-prepare.sh
open firefox-ios/Client.xcodeproj
```

Use the existing `Fennec` scheme with `Debug` for simulator work. The production device configuration is named `Firefox` in the upstream project. Internal module, target and scheme names remain upstream names; the delivered application is Aster.

The original support material is preserved in `README.upstream.md` and `docs/`. Upstream service credentials and branding permissions are not transferred by this fork.
