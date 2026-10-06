# Harbor 0.3 for iOS

SwiftUI / WKWebView browser for iOS 16+. Build with the included GitHub Actions workflow; the IPA is unsigned and requires your own signing.

## Browsing

Persistent bookmarks and history, regular-tab restoration, private tabs with a separate nonpersistent website store, recent closed tabs, four search engines, system/light/dark themes, page zoom, desktop mode, find in page, native JavaScript dialogs, sharing and link context menus. Downloads support preview, sharing, cancellation and deletion, and remain saved even when initiated from private tabs.

## Video compatibility

Inline playback, AirPlay, Picture in Picture and autoplay configuration are enabled. YouTube compatibility is on by default and bypasses content rules on youtube.com, its subdomains and youtu.be. This can allow ads; it is a playback-first workaround, not a claim of ad-free YouTube. Disable it in site controls to try filtering. JavaScript must remain enabled for YouTube. Autoplay preferences apply to new tabs.

## Protection

CI compiles AdGuard Base, Tracking Protection, Mobile Ads and Popups optimized filters to WebKit rules, retaining exceptions. Filter source/license reports are included in the app and CI artifacts. Custom WebKit JSON rules can be imported. Per-host exceptions and global toggles are available. Lists refresh with each app build; no background updater is included.

## Validation

CI validates the full rule pack in WebKit, builds an unsigned device app, and runs unit/UI tests on an iPhone simulator. Tests cover address parsing, private history, persistence, protection state transitions, actual local HTML5 video playback, native JavaScript confirmation, bookmarks and settings. A controlled video test does not certify live YouTube playback, DRM, every download endpoint or every website. Test YouTube on the signed physical-device build.
