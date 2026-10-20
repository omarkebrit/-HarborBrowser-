# Feature coverage

The current delivery candidate is full native [run 23](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39406335775), source `4557246b64453abb464844aa8ff4358e90107c5b`. Its 45 contract checks and full unit plan passed: 5,747 passed, zero failed and two unchanged upstream runtime skips (5,749 total). The cleaned WK observer case passed in 2.525s; all six corrected Summarize cases passed. Simulator host entitlements passed. Five-case media/session preflight is running; main UI, download and device-package results remain pending. It includes the core fixture/UI corrections and hides the unsupported crash-upload control using existing backend eligibility. Collection defaults remain off.

Full [run 22](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39405042843), source `5174b9a6775c0a0ada40bebf7c309ee300cf1bc5`, continues independently to verify the earlier core corrections; its native results remain pending. Run 20 also continues independently.

Native [run 20](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39394936415), source `273578ee85af23845bf517e76572f02a04a3f678`, is in progress. Its 45 local-contract checks passed in CI. Run 20's official unit result is 5,746 passed, one failed and two skipped (5,749 total). All six corrected async Summarize tests and their suite passed; the sole remaining unit failure is the WK WebView observer case's 30-second progress/content-size wait. Its five-case preflight finished with three passes, two failures and zero skips: first-loop rotation setup and tab 14 hittability failed. Its main UI selection passed all 16 cases with zero failures/skips, including all four media transports, first-loop boundary rotation and 25-tab restoration. The isolated download and exact-byte verification steps passed; device-package outcomes remain pending.

Targeted [diagnostic run 21](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39402334591), source `92473b44727bb14183775748a0d057ff35a0aae3`, finished with 232 passes and one reproduced synchronous-control failure (zero skips). The async unhosted variant passed; the original case is now made async with the same 30-second deadline and eight checks for full run 22. This comparison is not a full validation pass and produced no IPA.

[Run 18](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39379658275), source `7788245534fc23c00a93fb8375c83ebce8703a1e`, completed with four preflight passes, 14/15 main UI passes and a passing native download/integrity check. Units recorded 5,745 passed, two failed and two skipped. The unsigned iPhone build and actual-package audit passed, but the IPA was withheld because required tests failed. Recovery run 19 only extracted evidence, with its native job skipped. Run 20's five-case preflight failed 3/2, but its main UI later passed all 16; isolated download and exact-byte verification steps passed and device results remain pending. See [TEST-REPORT.md](TEST-REPORT.md) and [final evidence](docs/aster-validation/run18/README.md).

| Area | Aster implementation | Validation scope |
| --- | --- | --- |
| Browsing and navigation | Native WebKit, back/forward, reload, search, find in page | Upstream unit plan; local native navigation and URL-bar tests |
| Tabs | Upstream tab management and persistence | Run 18 preflight passed 25 loaded pages with exact counts, process relaunch and first-tab tray selection. All creation used the native tray; alternative context-menu route remains code-reviewed only |
| Private browsing | Separate nonpersistent web data and private history handling | Native cookie/localStorage isolation and exclusion from regular history |
| Advertising protection | AdGuard Base + Mobile Ads converted to native WebKit rules during CI | Real WebKit rule compilation; controlled blocked resource and site exception |
| Tracking protection | Upstream standard/strict native lists | Upstream content-blocker unit coverage; local acceptance |
| Fingerprinting defenses | Inherited blocking of known fingerprinter URLs; Brave-style canvas/audio fingerprint randomization is not integrated | Upstream list coverage; no fingerprint-randomization acceptance validation |
| Cookie-consent banners | No dedicated cookie-banner filter or automatic consent-rejection feature | Not implemented or acceptance-tested |
| HTTPS upgrades and HTTPS-only | Feature-gated WebKit upgrades on iOS 18.2+, with HTTP fallback; release-channel default off, developer/beta on. No user-facing strict HTTPS-only mode | Configuration unit assertions; actual upgrade/fallback network behavior unverified |
| Video and audio | Inline playback, gesture-based sound, MP4/HLS/blob/iframe, fullscreen | Run 20 main passed all 16 cases, including actual MP4/HLS/iframe/blob iterations, ordinary fullscreen and strict first-loop boundary rotation. The same run's earlier preflight setup missed that boundary. Exact offset/image review awaits full evidence; no production fix for run 17's stall is established |
| PiP and AirPlay | Native WebKit configuration enabled | Configuration unit assertions; actual hardware/receiver remains unverified |
| Downloads | Upstream native download manager | Run 18 passed the isolated native file download and exact 95-byte SHA-256 verification; remains required in run 20 |
| Reader/bookmarks/reading list | Upstream implementations | Native article save, reader rendering and reading-list presence |
| Passwords and autofill | Inherited password management and credential-provider extension | Upstream unit coverage; physical Face ID and signed extension need device testing |
| Appearance and accessibility | Aster light/dark palette, original icon, scalable text | Native large-text navigation and theme switching; source palette contrast checks |
| Languages | Upstream locales with app-name updates | String syntax checked; full translation and Arabic device review remain outstanding |
| Privacy consent | Optional collection defaults remain off; crash upload is unsupported for Aster and its main Settings control is hidden in run 23 | Consent and independent-toggle unit coverage; current eligibility/control change awaits native verification |
| Help and privacy notice | Bundled authenticated internal pages, readable offline | Native Settings navigation, visible notice content, authorization/resource unit assertions |
| Default browser | Apple-managed entitlement not included | Needs approval/provisioning before offering this capability |
| Account synchronization | Inherited Firefox Account provider code | Independent identifier/redirect and end-to-end service use unverified; onboarding promotion disabled |
| Brave Playlist and saved-media background playback | Not implemented | Needs a dedicated media library/player and device validation |
| Brave Sync, Rewards, Wallet, Leo, News and paid VPN | Not implemented | Requires separate implementations and/or service agreements |
| Installation | Unsigned device IPA built and audited in run 18 | Build 18.1/arm64/six extensions passed package audit; IPA withheld after test failures. Installation needs Apple signing |

The app still makes ordinary browser requests, including requested pages, search and provider resources. Disabling usage collection does not promise zero network activity. Ad blocking depends on the current rules and site behavior; video advertising and all tracking cannot be guaranteed absent.

The checked-in production advertising pack contains 40,723 rules generated and compiled with real WebKit in GitHub run 38083870485. CI refreshes and validates the pack before either testing or building. Its exact source URLs, hashes, conversion revision and rule count are recorded alongside `ads.json` in the filter artifact. Production generation fails if the converter or WebKit compilation fails.

The advertising pack is refreshed during builds; a background advertising-rule updater is not implemented in this fork. The bundled snapshot and conversion report are retained so the exact tested inputs can be inspected.
