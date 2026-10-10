# Harbor 0.4.0 for iOS

SwiftUI / WKWebView browser for iOS 16+, including iPhone 15 Pro Max. Build with GitHub Actions from your iPhone; no personal Mac is needed. The default IPA is unsigned and needs your own eligible signing method. An optional signed TestFlight workflow is available when you supply Apple distribution credentials. See [GitHub setup](GITHUB-SETUP.md).

Harbor is an independent browser, not full Brave feature parity. [Feature coverage](FEATURE-COVERAGE.md) lists what works and which Brave services are absent.

## 0.4.0

Optional main-page HTTPS upgrades, rejection of addresses containing embedded credentials, current-site data deletion, an app-switcher privacy cover, safer download deletion, and larger toolbar controls. Adds an original app icon, a privacy manifest, and opt-in signed CI distribution. Existing saved preferences migrate without resetting them.

## Browsing

Persistent bookmarks and history, regular-tab restoration, private tabs with a separate nonpersistent website store, recent closed tabs, four search engines, system/light/dark themes, page zoom, desktop mode, find in page, native JavaScript dialogs, sharing and link context menus. Downloads support preview, sharing, cancellation and deletion, and remain saved even when initiated from private tabs.

## Video compatibility

Inline playback, AirPlay, Picture in Picture and autoplay configuration are enabled. YouTube compatibility is on by default and bypasses content rules on youtube.com, its subdomains and youtu.be. This can allow ads; it is a playback-first workaround, not a claim of ad-free YouTube. Disable it in site controls to try filtering. JavaScript must remain enabled for YouTube. Autoplay preferences apply to new tabs.

## Protection

CI compiles AdGuard Base, Tracking Protection, Mobile Ads and Popups optimized filters to WebKit rules, retaining exceptions. Filter source/license reports are included in the app and CI artifacts. Custom WebKit JSON rules can be imported. Per-host exceptions and global toggles are available. Lists refresh with each app build; no background updater is included.

## Validation

CI validates the full rule pack in WebKit, builds an unsigned device app, and runs unit/UI tests on an iPhone simulator. Tests cover address parsing, private history, persistence, protection state transitions, actual local HTML5 video playback, native JavaScript confirmation, bookmarks and settings. A controlled video test does not certify live YouTube playback, DRM, every download endpoint or every website. Test YouTube on the signed physical-device build.

## 0.3.1 compatibility fixes

Tab cards are selectable across their full surface, with independent close controls and explicit sheet dismissal. Webviews attach inside a container when switching tabs. Video responses and player iframe navigations stay in WebKit rather than being treated as file downloads. Erome and its subdomains use video compatibility by default (filtering is paused, ads can appear); other hosts can opt in using site controls. No adult-content filter is included. YouTube automatic app handoffs are cancelled without repeatedly navigating the web page, and Safari-compatible browser tokens are appended to WebKit's actual device user agent. Retry preserves a failed initial URL. Existing preferences migrate without resetting them.

Regression checks include entire-card tab selection and returning to earlier tabs, HTTP range-based video playback, Erome compatibility against a deliberately blocking media rule using a controlled nonadult fixture, and live YouTube homepage rendering. The Erome test uses no real Erome content and does not certify playback of every live Erome video.
