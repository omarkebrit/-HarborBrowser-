# Aster for iPhone

A native iOS browser with a quiet sage, teal and slate interface, independent artwork, tabs, private browsing, downloads, reader mode and advertising protection. Designed for iPhone 15 Pro Max; supports iOS 15 and later where supported by the pinned upstream release.

Aster is an independent fork of [Firefox for iOS](https://github.com/mozilla-mobile/firefox-ios), pinned to `firefox-v158.0`, commit `1a0bf7b01230c165e8d66c7e07a66b7c8f52a83a`. Mozilla's mature browser foundation replaces the earlier Harbor implementation. Aster is not affiliated with Mozilla or Brave. The upstream source, MPL 2.0 license and third-party notices are preserved. See [README.upstream.md](README.upstream.md).

## Current delivery status

**No downloadable release or completed full-validation pass is available.** Full [run 23](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39406335775) passed units 5,747/0 failed/2 upstream skips but failed preflight 3/2, blocking its IPA; its main UI is running. Parallel [run 22](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39405042843) recorded units 5,745/2 failed/2 skipped.

Media-only [diagnostic 24](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39414241881), source `e0f89e5f8ce34e6faa230dac404b5a1434712486`, and WebEngine-only [diagnostic 25](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39414543028), source `1617b9a76839208c5f2ac533a646226929491787`, are running. They test fixture corrections and produce no IPA; the next full candidate has not started. See [TEST-REPORT.md](TEST-REPORT.md) for source-bound results, diagnostics and permanent evidence.

## What is included

- Real WKWebView browsing, persistent tabs, separate private storage, history, bookmarks, reading list, reader mode, search and native downloads.
- Native tracking protection plus bundled advertising rules, with an explicit exception for each site.
- Inline MP4, HLS, iframe and blob playback, Picture in Picture, AirPlay and HTML element fullscreen where supported by iOS and the website.
- Calm light and dark themes, scalable interface text, Arabic and other upstream locales, and original Aster artwork.
- Usage data, crash reports, daily usage, remote studies and rollouts disabled by default; enabling technical data does not silently enable studies.

Brave Playlist, Rewards, Wallet, Leo, Brave Sync and its paid VPN/backend services are not implemented. Native video playback does not provide a saved-media background-playback library. Firefox Account integration remains inherited provider code and is not certified for the independent app. Aster does not present Brave service substitutes or claim identical feature parity. Brave-style fingerprint randomization, cookie-consent automation and a strict HTTPS-only mode are also not implemented. See [ASTER-COVERAGE.md](ASTER-COVERAGE.md) for the exact scope.

## Build and install

Run **Build and test Aster for iPhone** in GitHub Actions. The workflow prepares pinned dependencies, generates and compiles a production advertising filter pack, runs the full upstream unit plan and native acceptance tests on an iPhone 15 Pro Max simulator, and builds an iPhone release app. It audits the actual unsigned package and publishes an IPA only if all required checks pass. Full delivery validation requires five preflight and 16 main UI cases plus the isolated download; diagnostics 24/25 do not replace these checks.

**Any IPA produced by this workflow is unsigned and requires valid Apple signing before installation on an iPhone.** GitHub compilation does not replace Apple's signing requirements. TestFlight requires an Apple Developer account, provisioning and App Store Connect credentials. No signing credentials are included. [BUILD-INSTALL.md](BUILD-INSTALL.md) explains the available routes. [دليل الآيفون بالعربي](INSTALL-AR.md).

The inherited application version stays `158.0` so upstream migration and feature gates keep working. The display name is Aster and the application identifier is `com.omarkebrit.aster`.

## Validation

[TEST-REPORT.md](TEST-REPORT.md) records the evidence and remaining limits. Simulator tests cannot certify all websites, protected DRM streams, physical-device battery use, AirPlay receivers, Face ID or signed installation. A decoded audio track in a simulator is not proof of sound output on a physical iPhone.

Active CI is limited to `.github/workflows/aster-ios.yml`. Upstream workflows are archived under `.github/upstream-workflows/` and do not execute. The previous Harbor app remains available in repository history and its existing branch.
