# Signing Aster for an iPhone

GitHub can build Aster without a local Mac. Its unsigned IPA still needs Apple signing before installation; tapping the file in Safari or Files does not install it. Passing simulator tests or a package audit does not establish signed-device compatibility.

## Apple signing or TestFlight

A signing workflow needs a valid Apple certificate **with its private key**, its password, and matching provisioning profiles. Store private signing material in GitHub Actions secrets, never in this public repository. [GitHub’s signing guide](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications) describes the certificate and profile setup.

Keep the app and all six extensions, with these seven profile assignments:

| Component | Bundle identifier |
| --- | --- |
| Main app | `com.omarkebrit.aster` |
| Widgets | `com.omarkebrit.aster.WidgetKit` |
| Notification service | `com.omarkebrit.aster.NotificationService` |
| Password AutoFill provider | `com.omarkebrit.aster.CredentialProvider` |
| Stickers | `com.omarkebrit.aster.Sticker` |
| Action extension | `com.omarkebrit.aster.ActionExtension` |
| Share extension | `com.omarkebrit.aster.ShareTo` |

Use one legitimate Apple team. Components sharing storage need the registered group `group.com.omarkebrit.aster`; keychain access must use the real App Identifier Prefix. If a signer changes identifiers, it must keep the app, extensions, group and keychain access consistent. Embedded executable code also needs correct signing.

Password AutoFill requires `com.apple.developer.authentication-services.autofill-credential-provider` in **both the main app and its credential-provider extension**, with suitable provisioning. Aster’s host declaration has been restored to match upstream; signed AutoFill remains unverified. [Apple’s entitlement requirement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.authentication-services.autofill-credential-provider).

[Ad hoc distribution](https://developer.apple.com/help/account/provisioning-profiles/create-an-ad-hoc-provisioning-profile/) additionally requires the iPhone’s registered device ID and a supported installation path. [TestFlight](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/) needs a developer team’s signed upload to App Store Connect, then allows installation through the free TestFlight app. The tester does not need to purchase their own developer membership. This repository has no configured signing credentials or TestFlight upload workflow.

## Conditional free route with only an iPhone

AltStore officially supports fully on-device setup of **Classic 2.3 through PAL on iOS 27**. PAL eligibility requires a matching Apple Account region and physical location in the **European Union, Japan or Brazil**. Earlier iOS versions may still need computer pairing. [AltStore’s announcement](https://bsky.app/profile/altstore.io/post/3mviuyldlt22q), [Apple’s regional requirements](https://support.apple.com/en-ie/118110).

Classic uses an Apple Account to sign apps. Its free-account limits are **10 App IDs, three sideloaded apps and seven-day renewal**. Aster alone needs seven IDs when all extensions are retained; other apps can consume the remaining quota. Installation setup uses Wi-Fi and LocalDevVPN. [AltStore’s App ID limits](https://faq.altstore.io/altstore-classic/app-ids), [installation and renewal limits](https://faq.altstore.io/altstore-classic/your-altstore).

This is a conditional option, **not a verified Aster installation route**. Before offering instructions, inspect the actual IPA’s embedded entitlements and confirm the signer preserves the required group, keychain and AutoFill capabilities for all components. Source entitlement files alone do not establish that an unsigned binary contains the metadata a signer discovers. Do not remove extensions or required capabilities to make signing appear successful. Signed installation and behavior must then be checked on the iPhone.
