# Building and installing Aster

## GitHub build

1. Resolve the billing/spending-limit block reported by [run 38086721963](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38086721963). That run did not execute any build or test steps; no IPA is available yet.
2. Open that run and select **Re-run jobs → Re-run all jobs**. GitHub supports rerunning within 30 days with repository write access. This reuses the exact tested branch reference and source commit containing the latest fullscreen test fix.
3. Review the native validation summary and evidence artifact. Required native checks must pass before an IPA is published.
4. Download **Aster-iPhone-UNSIGNED-needs-signing**. Extract `Aster-UNSIGNED-needs-signing.ipa`.

The workflow uses the standard `macos-26` runner and Xcode 26.5, pinned Swift package revisions, a verified Nimbus generator and a verified advertising converter. Native logs and test attachments are retained for seven days; download evidence if you need longer retention.

The workflow currently exists only on `feat/aster-browser`, while the repository's default branch remains `main`. GitHub requires a `workflow_dispatch` file on the default branch before offering manual **Run workflow** execution, so that button may be unavailable. Branch pushes without a skip-CI marker also trigger this workflow. No default-branch merge is required to rerun the existing run or trigger a branch push. See [GitHub's manual-workflow requirements](https://docs.github.com/en/actions/how-tos/managing-workflow-runs-and-deployments/managing-workflow-runs/manually-running-a-workflow) and [rerun instructions](https://docs.github.com/en/actions/how-tos/managing-workflow-runs-and-deployments/managing-workflow-runs/re-running-workflows-and-jobs).

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
