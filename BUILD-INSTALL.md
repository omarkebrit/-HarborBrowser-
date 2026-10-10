# Building and installing Aster

## GitHub build

1. Open the `feat/aster-browser` branch in the GitHub repository.
2. In Actions, select **Build and test Aster for iPhone** and run the workflow on this branch.
3. Review the native validation summary and evidence artifact. Required native checks must pass before an IPA is published.
4. Download **Aster-iPhone-UNSIGNED-needs-signing**. Extract `Aster-UNSIGNED-needs-signing.ipa`.

The workflow uses the standard `macos-26` runner and Xcode 26.5, pinned Swift package revisions, a verified Nimbus generator and a verified advertising converter. Native logs and test attachments are retained for seven days; download evidence if you need longer retention.

## Installing on an iPhone

An unsigned IPA cannot be installed directly by tapping it in Safari. A signing service must sign the app and its embedded extensions with a valid certificate and matching provisioning profiles. A multi-extension app may need separate bundle identifiers and app-group entitlements in those profiles. Do not assume a generic one-file signing tool supports this automatically.

For a supported TestFlight route, use an Apple Developer membership and App Store Connect, register the app and extension identifiers, configure certificates/profiles, then add a signed archive/export workflow. This repository has no Apple credentials and does not upload to TestFlight.

With only an iPhone and no Apple Developer setup or compatible signing service, GitHub can deliver the compiled file but cannot provide a signed installation. This limit comes from iOS installation rules.

The application identifier is `com.omarkebrit.aster`; the app group is `group.com.omarkebrit.aster`. The main application does not request Mozilla's managed default-browser entitlement. Additional managed capabilities require Apple's approval and appropriate provisioning.

## Local native development

On a Mac with Xcode 26.5, Node 24 and Python 3.12:

```sh
bash scripts/aster-ci-prepare.sh
open firefox-ios/Client.xcodeproj
```

Use the existing `Fennec` scheme with `Debug` for simulator work. The production device configuration is named `Firefox` in the upstream project. Internal module, target and scheme names remain upstream names; the delivered application is Aster.

The original support material is preserved in `README.upstream.md` and `docs/`. Upstream service credentials and branding permissions are not transferred by this fork.
