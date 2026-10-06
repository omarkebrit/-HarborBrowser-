# Harbor Browser — iOS prototype 0.1

A native SwiftUI / WKWebView browser for iPhone and iPad, iOS 16+.

## GitHub build without a Mac

See `GITHUB-SETUP.md`. Included Actions workflow builds an unsigned iPhone IPA and a simulator app. Installation still requires signing. CI has not been run yet.

## تشغيل التطبيق

1. على Mac، افتح `HarborBrowser.xcodeproj` بواسطة Xcode.
2. اختار iPhone Simulator واضغط Run لتجربة التطبيق.
3. للتثبيت على iPhone: سجّل Apple Account في إعدادات Xcode، ثم اختار Team ضمن Signing & Capabilities. غيّر Bundle Identifier إذا لزم.
4. اختار الآيفون الموصول كجهاز التشغيل واضغط Run. فعّل Developer Mode إذا طلب النظام.

هذا مشروع كود، وليس IPA موقّعاً جاهزاً للتثبيت. الحساب الشخصي المجاني يتطلب إعادة التثبيت دورياً حسب قيود Apple.

## Included

- Address/search bar using DuckDuckGo; HTTPS is used for addresses without a scheme.
- Back, forward, reload, share, regular/private tabs.
- WebKit rules compiled and installed before the first navigation.
- 36 selected third-party ad/tracker domains, third-party cookie blocking, four cosmetic selectors.
- Protection switch per tab; settings; clear cookies/cache/site storage and close tabs.
- Custom WebKit JSON import (maximum 50,000 rules / 20 MB); validation by WebKit before replacement. Imported rules survive app restarts.
- No analytics SDK, accounts, or automatic external filter fetches.

## Protection limits

This is a starter prototype, not verified Brave parity. The bundled list is intentionally small. It has no automatic filter updates, advanced fingerprint randomization, adblock-scriptlet engine, malicious-site reputation service, or guaranteed YouTube/video ad removal. Popups without a user-clicked link are suppressed; clicked new-window links open in the current tab. JavaScript confirm/prompt dialogs currently return cancel; this can break some site workflows. HTTP-only sites may be restricted by the platform's default transport policy. It is not a system-wide blocker or Safari extension.

Private tabs share one nonpersistent data store, replaced once the last private tab closes. Normal site storage persists; tab/session history itself is not restored after relaunch. Private browsing does not hide IP addresses or network activity from the network provider.

## Stronger filter coverage

Import a trusted, licensed content-blocker JSON array via Settings. Plain EasyList/AdGuard text files are NOT directly accepted. AdGuard's SafariConverterLib can convert supported text rules to WebKit JSON, but advanced rules require a separate implementation. Verify license obligations before redistribution. Baseline and custom lists are separate: exceptions inside one cannot override the other. The per-tab protection switch disables both lists. Re-importing replaces the prior custom list and reloads existing tabs.

## Validation status

JSON structure, representative domain regex matching, and project source/resource references were checked in the build environment. No Apple SDK, Swift compiler, Xcode, Simulator or physical device was available there. Compilation and runtime behavior remain unverified.

On a Mac, build first:

```sh
xcodebuild -project HarborBrowser.xcodeproj -scheme HarborBrowser -sdk iphonesimulator -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

Then test: initial rule loading, regular/private tabs, blocked third-party requests with a controlled fixture, first-party requests allowed, cookie/login compatibility, imports with invalid and valid JSON, shield toggling, popups, data clearing, and persistence after relaunch. Compare the same sites with Brave before making claims about comparable protection.

## References

- https://developer.apple.com/documentation/webkit/wkcontentruleliststore
- https://webkit.org/blog/3476/content-blockers-first-look/
- https://developer.apple.com/documentation/xcode/running-your-app-on-simulated-or-physical-devices
- https://github.com/AdguardTeam/SafariConverterLib

Starter rules and app source are original project code, licensed under MIT. Third-party filter imports retain their own licenses.
