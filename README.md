# Harbor Browser 0.2 — iOS

SwiftUI / WKWebView browser for iPhone and iPad, iOS 16+.

## Improved blocking

GitHub builds bundle AdGuard's iOS optimized Base, Tracking Protection, Mobile Ads and Popups filters, converted using the checksum-pinned SafariConverterLib 4.3.0 CLI. This replaces the tiny starter-domain list in built artifacts. Supported URL/path/resource-type blocking and cosmetic hiding rules are retained with their exceptions in one compiled WebKit list. Third-party cookie blocking precedes those rules. Imported JSON is appended to the same list so its exceptions can override earlier rules.

The converter's unsupported rules are reported; advanced scriptlets, procedural cosmetic rules and HTML/video modification are not implemented. This app does not claim complete AdGuard or Brave equivalence or guaranteed YouTube ad removal. Rule counts measure loaded rules, not blocked requests.

Filters refresh during each GitHub build, not silently while browsing. The bundled pack works offline. Lists and converter failures stop CI instead of shipping a false enhanced-protection claim. Local builds without generated filters clearly report the starter fallback.

## Browser features

Address/search bar, DuckDuckGo search, back/forward/reload/share, regular and private tabs, per-tab protection toggle, imported WebKit JSON rules and clearing cookies/site storage. Private tabs share a nonpersistent store, discarded after closing the last private tab. Browsing privately does not hide IP addresses.

Imported lists have a combined limit of 150,000 rules and 64 MB JSON. Invalid imports leave the previous list active. The compiled list is cached by SHA-256; first compilation may take time. No analytics SDK or account is included.

## Build and install

See `GITHUB-SETUP.md`. Actions generates filters, checks the complete pack using WebKit, builds device/simulator targets and uploads an unsigned IPA. Signing is required before installing on an iPhone. No Apple secrets are needed for unsigned builds.

On macOS, open the project with Xcode. To include enhanced filters locally:

```sh
python3 scripts/prepare_filters.py
swift scripts/validate_filters.swift HarborBrowser/Filters/enhanced.json
xcodebuild -project HarborBrowser.xcodeproj -scheme HarborBrowser -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO build
```

To install on a device with Xcode, select your team under Signing & Capabilities, use a unique bundle identifier and run on your connected device.

## Verification and limits

Version 0.1 successfully compiled for device and simulator on GitHub. Version 0.2 adds full filter compilation checks. Real-site ad coverage, cookie/login compatibility, imported exceptions, cache behavior and protection toggling must still be tested on iPhone. Disable the shield for a tab if a site breaks. Downloads, tab restoration, site allowlists and JavaScript confirm/prompt UI are not implemented. HTTP-only sites may be restricted by the platform transport policy.

## Attribution

App source is MIT licensed. The converted filters retain their respective authors' licenses and notices. The IPA contains the downloaded source lists, their hashes, conversion report, attribution and GPL/LGPL license texts in `Filters`. The GPL converter executable is a build-only tool and is not bundled or linked into the app. Original resources:

- https://github.com/AdguardTeam/FiltersRegistry
- https://github.com/AdguardTeam/SafariConverterLib/tree/v4.3.0
- https://developer.apple.com/documentation/webkit/wkcontentruleliststore
