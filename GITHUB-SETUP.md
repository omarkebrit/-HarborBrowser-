# Build without owning a Mac

GitHub Actions runs Xcode on a hosted macOS machine. This repository includes a manually runnable workflow and a shared Xcode scheme.

## Upload from a computer or phone

1. Create a GitHub repository.
2. Extract the source ZIP. Upload the CONTENTS of `HarborBrowser` to the repository root, including `.github/workflows/build-ios.yml` and the `HarborBrowser.xcodeproj` folder. GitHub cannot run a workflow from a ZIP left in the repository.
3. If your file browser hides `.github`, use GitHub's **Add file → Create new file** and enter `.github/workflows/build-ios.yml`, then paste the supplied workflow. All source/project files must also be uploaded as actual files.
4. Open the repository's **Actions** tab. Enable Actions if prompted, select **Build Harbor for iPhone**, and select **Run workflow**.
5. When finished, open the run and download **Harbor-iPhone-UNSIGNED-needs-signing** under Artifacts. Extract its ZIP to get `Harbor-unsigned.ipa`.
6. If a job fails, inspect its build log. The code has not yet been compiled with Apple's SDK in the author's environment; first-run build fixes may be needed.

The workflow finds the project even if it was uploaded in a nested folder. The workflow itself MUST be at `.github/workflows/build-ios.yml` at the repository root.

## Installation is separate

The IPA produced by this workflow is deliberately unsigned. It cannot install directly by tapping it on an iPhone. It must first be signed for an eligible device/distribution method. No Apple credentials are required for this unsigned build.

Official registered-device distribution needs appropriate Apple certificates and provisioning profiles. TestFlight distribution requires Apple Developer Program membership and an App Store Connect setup. Signed GitHub CI requires importing those signing assets via encrypted repository secrets; do not commit credentials or certificates to the repository.

An alternative sideloading route may use a Windows computer and a compatible signing/installation tool. Its current device support, Apple account requirements, and re-signing interval must be checked before choosing it. This package does not configure such a tool.

The simulator artifact runs only in an iOS Simulator on a Mac; it cannot run on an iPhone.

## What this build verifies

The workflow builds both device and simulator targets. It does not run runtime, ad-block coverage or privacy tests. A successful run confirms compilation, not Brave-equivalent protection. Hosted runner usage is subject to the repository's GitHub Actions plan and billing limits.

References:
- https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications
- https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices
