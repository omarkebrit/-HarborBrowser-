# Aster for iPhone

A native iOS browser with a quiet sage, teal and slate interface, independent artwork, tabs, private browsing, downloads, reader mode and advertising protection. Designed for iPhone 15 Pro Max; supports iOS 15 and later where supported by the pinned upstream release.

Aster is an independent fork of [Firefox for iOS](https://github.com/mozilla-mobile/firefox-ios), pinned to `firefox-v158.0`, commit `1a0bf7b01230c165e8d66c7e07a66b7c8f52a83a`. Mozilla's mature browser foundation replaces the earlier Harbor implementation. Aster is not affiliated with Mozilla or Brave. The upstream source, MPL 2.0 license and third-party notices are preserved. See [README.upstream.md](README.upstream.md).

## Current delivery status

The current delivery candidate is full native [run 23](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39406335775), source `4557246b64453abb464844aa8ff4358e90107c5b`. Its 45 contract checks and full unit plan passed: 5,747 passed, zero failed and two unchanged upstream runtime skips (5,749 total). The cleaned WK observer case passed in 2.525s; all six corrected Summarize cases passed. Simulator host entitlements passed. Five-case media/session preflight is running; main UI, download and device-package results remain pending. It includes the core fixture/UI corrections and hides the unsupported crash-upload control using existing backend eligibility. Collection defaults remain off.

Full [run 22](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39405042843), source `5174b9a6775c0a0ada40bebf7c309ee300cf1bc5`, continues independently to verify the earlier core corrections; its native results remain pending. Run 20 also continues independently.

The [repository](https://github.com/omarkebrit/-HarborBrowser-) is public, including the earlier Harbor branches and history. Aster's source is on `feat/aster-browser`. Native [run 20](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39394936415), source `273578ee85af23845bf517e76572f02a04a3f678`, is in progress. Its 45 local-contract checks passed in CI. Run 20's official unit result is 5,746 passed, one failed and two skipped (5,749 total). All six corrected async Summarize tests and their suite passed; the sole remaining unit failure is the WK WebView observer case's 30-second progress/content-size wait. Its five-case preflight finished with three passes, two failures and zero skips: first-loop rotation setup and tab 14 hittability failed. Its main UI selection passed all 16 cases with zero failures/skips, including all four media transports, first-loop boundary rotation and 25-tab restoration. The isolated download and exact-byte verification steps passed; device-package outcomes remain pending.

Targeted [diagnostic run 21](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39402334591), source `92473b44727bb14183775748a0d057ff35a0aae3`, finished with 232 passes and one reproduced synchronous-control failure (zero skips). The async unhosted variant passed; the original case is now made async with the same 30-second deadline and eight checks for full run 22. This comparison is not a full validation pass and produced no IPA.

[Run 18](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39379658275), source `7788245534fc23c00a93fb8375c83ebce8703a1e`, completed with four preflight passes, 14/15 main UI passes and a passing native download/integrity check. The full unit plan recorded 5,745 passes, two failures and two skips.

The unsigned iPhone release build and actual-package audit passed, but the IPA was withheld because required tests failed. **No downloadable release or full-validation pass is available.** The main failure concerned the first MP4 status label's hittability despite visible decoded playback; run 20 has verified the Summarize correction while the WK observer case still fails. Run 20's later 16-case main pass does not erase its unit/preflight failures; download and exact-byte verification steps passed and device results remain pending. [Final evidence](docs/aster-validation/run18/README.md) and [TEST-REPORT.md](TEST-REPORT.md) record the exact results, recovery-only run 19 and remaining limits. No production playback fix or signed installation is established.

## What is included

- Real WKWebView browsing, persistent tabs, separate private storage, history, bookmarks, reading list, reader mode, search and native downloads.
- Native tracking protection plus bundled advertising rules, with an explicit exception for each site.
- Inline MP4, HLS, iframe and blob playback, Picture in Picture, AirPlay and HTML element fullscreen where supported by iOS and the website.
- Calm light and dark themes, scalable interface text, Arabic and other upstream locales, and original Aster artwork.
- Usage data, crash reports, daily usage, remote studies and rollouts disabled by default; enabling technical data does not silently enable studies.

Brave Playlist, Rewards, Wallet, Leo, Brave Sync and its paid VPN/backend services are not implemented. Native video playback does not provide a saved-media background-playback library. Firefox Account integration remains inherited provider code and is not certified for the independent app. Aster does not present Brave service substitutes or claim identical feature parity. Brave-style fingerprint randomization, cookie-consent automation and a strict HTTPS-only mode are also not implemented. See [ASTER-COVERAGE.md](ASTER-COVERAGE.md) for the exact scope.

## Build and install

Run **Build and test Aster for iPhone** in GitHub Actions. The workflow prepares pinned dependencies, generates and compiles a production advertising filter pack, runs the full upstream unit plan and native acceptance tests on an iPhone 15 Pro Max simulator, and builds an iPhone release app. It audits the actual unsigned package and publishes an IPA only if all required checks pass. The current delivery candidate, run 23, requires five preflight and 16 main UI cases plus the isolated download; its boundary-timed rotation result remains pending.

**Any IPA produced by this workflow is unsigned and requires valid Apple signing before installation on an iPhone.** GitHub compilation does not replace Apple's signing requirements. TestFlight requires an Apple Developer account, provisioning and App Store Connect credentials. No signing credentials are included. [BUILD-INSTALL.md](BUILD-INSTALL.md) explains the available routes. [دليل الآيفون بالعربي](INSTALL-AR.md).

The inherited application version stays `158.0` so upstream migration and feature gates keep working. The display name is Aster and the application identifier is `com.omarkebrit.aster`.

## Validation

[TEST-REPORT.md](TEST-REPORT.md) records the evidence and remaining limits. Simulator tests cannot certify all websites, protected DRM streams, physical-device battery use, AirPlay receivers, Face ID or signed installation. A decoded audio track in a simulator is not proof of sound output on a physical iPhone.

Active CI is limited to `.github/workflows/aster-ios.yml`. Upstream workflows are archived under `.github/upstream-workflows/` and do not execute. The previous Harbor app remains available in repository history and its existing branch.
