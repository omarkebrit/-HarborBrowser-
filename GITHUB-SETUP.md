# Build and install Harbor using an iPhone

GitHub Actions supplies the Mac and Xcode. You can control the workflow from Safari on your iPhone 15 Pro Max. Harbor supports iOS 16 or later. Building an app and installing it are separate steps: the normal workflow produces an unsigned IPA, while the optional Apple signing and TestFlight jobs provide an installation route when you supply the required Apple credentials.

## Run the normal build from your iPhone

1. Open your repository in Safari. If starting with a source ZIP, extract it in Files and upload its **contents** as actual files, including `HarborBrowser.xcodeproj`, the source/test folders, `scripts`, and `.github/workflows/build-ios.yml`. A ZIP committed by itself cannot run as an Xcode project. Keep the workflow at the repository root even if the app project is in a nested folder. If `.github` is hidden, use **Add file → Create new file** to create that exact workflow path.
2. Open **Actions → Build Harbor for iPhone → Run workflow**. Use Safari's **Request Desktop Website** if the controls are hidden. Select the branch containing these changes.
3. Leave **signed_testflight** and **upload_testflight** unchecked. Both default to `false`. Run the workflow.
4. Open the completed run to view its build/test logs and download artifacts. **Harbor-iPhone-UNSIGNED-needs-signing** contains `Harbor-unsigned.ipa`; this does **not** install by tapping it on your iPhone. It is published only after all browser tests succeed. **Harbor-Simulator-only** runs in a Mac's iOS Simulator and cannot run on an iPhone. Screenshots, test results and video-fixture request logs are separate artifacts.

The normal build needs no Apple signing credentials and also runs on pushes to `main`/`master` and pull requests targeting those branches. GitHub requires the manually runnable workflow to exist on the default branch; merge the workflow changes there before using its new manual options. Hosted runner usage depends on your GitHub Actions plan and billing limits. [GitHub manual workflows](https://docs.github.com/en/actions/how-tos/manage-workflow-runs/manually-run-a-workflow)

## What you need for TestFlight

- An active Apple Developer Program membership with permission to manage distribution signing assets, plus an App Store Connect app record.
- A password-protected **Apple Distribution** P12 containing both its certificate **and private key**. A downloaded `.cer` file alone is insufficient.
- A current **App Store Connect distribution provisioning profile** for an explicit bundle identifier, associated with that same certificate. Development, Ad Hoc, enterprise, wildcard, and expired profiles are rejected.
- For upload, an App Store Connect **team API key** with permission to upload builds: its key ID, issuer ID, and downloaded `.p8` private key.

The workflow derives the Apple team ID, app bundle ID, and profile UUID directly from the profile. Register that bundle ID with Apple and select the same ID in your App Store Connect app record. No placeholder team ID or bundle ID needs editing in the project.

GitHub supplies a build machine, not Apple membership, certificates, private keys, profiles, or App Store Connect access. If you do not already have these assets, a developer/admin must prepare them or you must arrange a separate secure certificate-issuance setup. Apple's documented CSR setup uses Keychain Access on a Mac; this repository does not implement certificate issuance or enrollment. Owning only an iPhone is sufficient to trigger a **configured** workflow, but does not eliminate that setup requirement. [Apple signing assets](https://developer.apple.com/help/account/certificates/create-a-certificate-signing-request), [GitHub Apple signing](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications)

## Configure repository secrets in Safari

Open **Settings → Secrets and variables → Actions → New repository secret**. Add these exact names. Store credentials as secrets; never upload them as repository files. Base64 is a text encoding, not encryption. Get prepared Base64 values through your signing administrator or a trusted local/private tool.

| Secret | Value |
| --- | --- |
| `APPLE_DISTRIBUTION_P12_BASE64` | Base64 contents of the Apple Distribution P12, including its private key. |
| `APPLE_DISTRIBUTION_P12_PASSWORD` | Nonempty password protecting that P12. |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Base64 contents of the matching `.mobileprovision` App Store Connect profile. |
| `ASC_API_KEY_ID` | App Store Connect team API key ID; required only for upload. |
| `ASC_API_ISSUER_ID` | Issuer UUID for that team API key; required only for upload. |
| `ASC_API_KEY_P8_BASE64` | Base64 contents of the downloaded `.p8` private key; required only for upload. |

The P12 and profile are imported only in the manually selected signing job. The API private key is decoded only in the explicitly selected upload job. The script uses a temporary keychain and removes the imported profiles, certificate files, and API key on exit; workflow cleanup also runs after failures/cancellation. Signed artifacts have a three-day retention period and are accessible to users who can download your repository's Actions artifacts.

## Choose signed export or TestFlight upload

In **Actions → Build Harbor for iPhone → Run workflow**:

| `signed_testflight` | `upload_testflight` | Result |
| --- | --- | --- |
| `false` | `false` | Normal unsigned build and simulator tests only. |
| `true` | `false` | After tests pass, sign/archive/export **Harbor-AppStore-SIGNED**. No Apple upload. |
| `true` | `true` | After tests and signed export pass, explicitly upload that IPA to App Store Connect for TestFlight. |
| `false` | `true` | Rejected: upload requires a signed build. |

Signing uses `scripts/ci-sign-ios.sh archive`; the separate upload job uses its `upload` command. Both jobs require Xcode 26 or later and the iOS 26 SDK or later to meet Apple's current upload minimum. This SDK requirement does not change Harbor's iOS 16 deployment target. Each signed run gets a build version based on the GitHub run number and attempt. If you already distributed this app under a higher build version, check that the new version exceeds the last uploaded version. [Apple SDK minimum](https://developer.apple.com/news/upcoming-requirements/?id=04282026a)

An App Store-signed IPA artifact also does **not** install directly from Files. For the iPhone-only installation route, select both inputs, wait for Apple's processing, and open the app's **TestFlight** section in App Store Connect. Complete any required export-compliance information and add yourself as an eligible internal tester. Open the invitation using Apple's TestFlight app on your iPhone, then install Harbor there. External testing may need Apple's beta review. TestFlight builds expire after 90 days. Uploading here does not submit or publish an App Store release. [Apple TestFlight overview](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/), [Apple build uploads](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds)

## What the checks establish

The workflow cleans both builds, compiles the device app, validates the generated content-rule pack with WebKit, and runs native unit/UI tests on an iPhone 15 Pro Max simulator. Video regressions check actual decoded frames and advancing playback time with the production filter pack, MP4/HLS, seeking, iframe/blob players, user-tapped pop-ups, sound, HTML full screen/rotation and the bundled offline video check. The signed export/upload path needs its own run with your Apple assets; it has not been verified by the unsigned build.

After installing version **0.5.0**, open **Menu → Video playback check → Play test video** to check picture and sound on your iPhone. For a website with a broken player, open **Site controls → Reload for video playback**. This enables JavaScript/autoplay, switches to the mobile page and pauses filters for that site; ads may appear. Settings changes keep submitted forms open rather than resubmitting them—use a new tab for those pages.

Successful CI does not certify all live websites, YouTube/DRM behavior, download endpoints, or Brave-equivalent protection. Harbor is a SwiftUI/WKWebView browser with the features described in [README.md](README.md), not a full reproduction of Brave's services or engine behavior. Becoming selectable as the iPhone's default browser separately requires Apple's managed default-browser entitlement, which this setup does not request. [Apple default-browser requirements](https://developer.apple.com/documentation/Xcode/preparing-your-app-to-be-the-default-browser)
