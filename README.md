# Aster for iPhone

A native iOS browser with a quiet sage, teal and slate interface, independent artwork, tabs, private browsing, downloads, reader mode and advertising protection. Designed for iPhone 15 Pro Max; supports iOS 15 and later where supported by the pinned upstream release.

Aster is an independent fork of [Firefox for iOS](https://github.com/mozilla-mobile/firefox-ios), pinned to `firefox-v158.0`, commit `1a0bf7b01230c165e8d66c7e07a66b7c8f52a83a`. Mozilla's mature browser foundation replaces the earlier Harbor implementation. Aster is not affiliated with Mozilla or Brave. The upstream source, MPL 2.0 license and third-party notices are preserved. See [README.upstream.md](README.upstream.md).

## Current delivery status

The [repository](https://github.com/omarkebrit/-HarborBrowser-) is public, including the earlier Harbor branches and history. Aster's source is on `feat/aster-browser`. [Run 18](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39379658275), attempt 1, source `7788245534fc23c00a93fb8375c83ebce8703a1e`, has passed all four media/session preflight cases with zero failures or skips. **No production IPA or full-validation pass is available yet.**

The checkpoint includes fresh decoded video frames through two landscape loops and 25-tab creation/restoration. The full unit stage failed; diagnosis awaits final logs. The main 15-case UI stage also failed, with its case-level results not yet available. The isolated native download and exact 95-byte integrity check passed; device build/audit results remain pending. Production playback behavior was unchanged by the read-only diagnostics, so this pass does not establish a fix for run 17's stall. Independent stages continue collecting results, while IPA publication requires all required checks to pass. See [TEST-REPORT.md](TEST-REPORT.md) and [native screenshots](docs/aster-screenshots/README.md).

## What is included

- Real WKWebView browsing, persistent tabs, separate private storage, history, bookmarks, reading list, reader mode, search and native downloads.
- Native tracking protection plus bundled advertising rules, with an explicit exception for each site.
- Inline MP4, HLS, iframe and blob playback, Picture in Picture, AirPlay and HTML element fullscreen where supported by iOS and the website.
- Calm light and dark themes, scalable interface text, Arabic and other upstream locales, and original Aster artwork.
- Usage data, crash reports, daily usage, remote studies and rollouts disabled by default; enabling technical data does not silently enable studies.

Brave Playlist, Rewards, Wallet, Leo, Brave Sync and its paid VPN/backend services are not implemented. Native video playback does not provide a saved-media background-playback library. Firefox Account integration remains inherited provider code and is not certified for the independent app. Aster does not present Brave service substitutes or claim identical feature parity. Brave-style fingerprint randomization, cookie-consent automation and a strict HTTPS-only mode are also not implemented. See [ASTER-COVERAGE.md](ASTER-COVERAGE.md) for the exact scope.

## Build and install

Run **Build and test Aster for iPhone** in GitHub Actions. The workflow prepares pinned dependencies, generates and compiles a production advertising filter pack, runs the full upstream unit plan and native acceptance tests on an iPhone 15 Pro Max simulator, and builds an iPhone release app. It audits the actual unsigned package and publishes an IPA only if all required checks pass. The prepared next candidate expands selection to five preflight and 16 main UI cases plus the isolated download; its new boundary-timed rotation case has not run natively.

**Any IPA produced by this workflow is unsigned and requires valid Apple signing before installation on an iPhone.** GitHub compilation does not replace Apple's signing requirements. TestFlight requires an Apple Developer account, provisioning and App Store Connect credentials. No signing credentials are included. [BUILD-INSTALL.md](BUILD-INSTALL.md) explains the available routes. [دليل الآيفون بالعربي](INSTALL-AR.md).

The inherited application version stays `158.0` so upstream migration and feature gates keep working. The display name is Aster and the application identifier is `com.omarkebrit.aster`.

## Validation

[TEST-REPORT.md](TEST-REPORT.md) records the evidence and remaining limits. Simulator tests cannot certify all websites, protected DRM streams, physical-device battery use, AirPlay receivers, Face ID or signed installation. A decoded audio track in a simulator is not proof of sound output on a physical iPhone.

Active CI is limited to `.github/workflows/aster-ios.yml`. Upstream workflows are archived under `.github/upstream-workflows/` and do not execute. The previous Harbor app remains available in repository history and its existing branch.
