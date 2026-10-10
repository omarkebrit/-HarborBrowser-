# Harbor and Brave on iPhone

Harbor is an independent SwiftUI/WebKit browser for iOS 16 or later, including iPhone 15 Pro Max. It is not a complete Brave replacement. The table describes implemented behavior, not a security audit or a promise about every website.

| Capability | Harbor |
| --- | --- |
| Website browsing, back/forward, reload, tabs | Implemented; normal tabs can restore after relaunch. |
| Private browsing | Separate nonpersistent website storage; private URLs do not enter history, restored tabs, or recently closed tabs. Private tabs share a temporary session until all are closed. This does not hide traffic from websites or network providers. |
| Bookmarks and history | Local storage, search, opening, editing, and deletion. No cloud sync or Safari import. |
| Downloads | Native WebKit downloads, cancellation, preview, sharing, deletion. Saved files remain on disk even when downloaded in private tabs. No resumable transfer manager. |
| Ad/tracker filtering | AdGuard lists converted to WebKit rules at build time, custom JSON import, global and site controls. Coverage differs from Brave Shields. Lists do not refresh while the app is running. |
| Video compatibility | Inline video, AirPlay and Picture in Picture configuration. Compatibility mode disables filtering on selected sites; ads may appear. No guarantee of playback or ad removal on every video service. |
| HTTPS upgrade | Optional upgrade of main-page HTTP URLs to HTTPS. No automatic downgrade after TLS errors. It does not upgrade every subresource or implement full mixed-content blocking. |
| Delete one website's data | Current-site cookies and matching WebKit records can be cleared; shared parent-domain data may also be removed. History, bookmarks and downloaded files remain. |
| App-switcher privacy | Neutral cover obscures browser content and sheets while the app is inactive. This is not a biometric app lock. |
| Search choice, desktop mode, page zoom, find, share | Implemented. Brave Search is one selectable web search engine; this does not include Brave Leo. |
| Theme and accessibility | System/light/dark appearance, native controls, larger toolbar touch targets, responsive tab grid. No forced dark rendering of arbitrary websites. |
| Default iPhone browser | Not enabled. Requires Apple's managed browser entitlement and approved distribution configuration. |
| Brave Sync, Wallet, Leo, News, Rewards, Firewall/VPN | Not implemented. These services cannot be obtained merely by renaming the app or enabling a UI toggle. |
| Fingerprinting defenses, Global Privacy Control, automatic cookie-banner removal | No equivalent implementation or audited claim. WebKit supplies its own platform protections; the filter pack is not Brave's privacy engine. |

GitHub Actions can build this project without your own Mac. Its normal device artifact is **unsigned** and requires a separate eligible signing/installation method. The optional TestFlight workflow requires your Apple distribution assets and App Store Connect setup. See [GITHUB-SETUP.md](GITHUB-SETUP.md).

If you need every feature offered by Brave on iPhone now, use the [official Brave iPhone app](https://apps.apple.com/app/id1052879175). Its feature set differs from desktop Brave and some services require a subscription.

References checked on 2026-10-10: [Brave's iPhone App Store listing](https://apps.apple.com/app/id1052879175), [Apple's browser entitlement documentation](https://developer.apple.com/documentation/xcode/preparing-your-app-to-be-the-default-browser), [GitHub's Xcode signing guide](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications).
