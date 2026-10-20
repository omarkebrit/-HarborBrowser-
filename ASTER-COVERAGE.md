# Feature coverage

As of 20 October 2026, [run 18](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39379658275), attempt 1, source `7788245534fc23c00a93fb8375c83ebce8703a1e`, has an official four-pass preflight checkpoint with zero failures/skips. It includes fresh decoded frames through two landscape loops and 25-tab restoration. The full unit stage failed with diagnosis pending final logs; main UI is running and download/device-package results remain pending. Read-only diagnostics did not change production playback behavior, so this pass does not establish a fix for run 17's stall. No IPA or full-validation pass exists. See [TEST-REPORT.md](TEST-REPORT.md).

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
| Video and audio | Inline playback, gesture-based sound, MP4/HLS/blob/iframe, fullscreen | Run 18 preflight passed popup/restrictive autoplay and fullscreen rotation with two landscape end/start transitions plus fresh decoded frames; exit → menu → Settings → browser also passed. Full main selection remains running; this does not establish a fix for run 17's stall. A separate first-loop boundary rotation case is prepared for the next candidate, requiring 5 preflight/16 main cases; its native result is pending |
| PiP and AirPlay | Native WebKit configuration enabled | Configuration unit assertions; actual hardware/receiver remains unverified |
| Downloads | Upstream native download manager | Dedicated native file/download-byte check remains unexecuted; required in the next native run |
| Reader/bookmarks/reading list | Upstream implementations | Native article save, reader rendering and reading-list presence |
| Passwords and autofill | Inherited password management and credential-provider extension | Upstream unit coverage; physical Face ID and signed extension need device testing |
| Appearance and accessibility | Aster light/dark palette, original icon, scalable text | Native large-text navigation and theme switching; source palette contrast checks |
| Languages | Upstream locales with app-name updates | String syntax checked; full translation and Arabic device review remain outstanding |
| Privacy consent | Technical data, crashes, daily usage, studies and rollouts default off | Consent and independent-toggle unit coverage |
| Help and privacy notice | Bundled authenticated internal pages, readable offline | Native Settings navigation, visible notice content, authorization/resource unit assertions |
| Default browser | Apple-managed entitlement not included | Needs approval/provisioning before offering this capability |
| Account synchronization | Inherited Firefox Account provider code | Independent identifier/redirect and end-to-end service use unverified; onboarding promotion disabled |
| Brave Playlist and saved-media background playback | Not implemented | Needs a dedicated media library/player and device validation |
| Brave Sync, Rewards, Wallet, Leo, News and paid VPN | Not implemented | Requires separate implementations and/or service agreements |
| Installation | Planned unsigned device IPA from GitHub | Device build and IPA audit remain pending; no IPA produced; installation needs Apple signing |

The app still makes ordinary browser requests, including requested pages, search and provider resources. Disabling usage collection does not promise zero network activity. Ad blocking depends on the current rules and site behavior; video advertising and all tracking cannot be guaranteed absent.

The checked-in production advertising pack contains 40,723 rules generated and compiled with real WebKit in GitHub run 38083870485. CI refreshes and validates the pack before either testing or building. Its exact source URLs, hashes, conversion revision and rule count are recorded alongside `ads.json` in the filter artifact. Production generation fails if the converter or WebKit compilation fails.

The advertising pack is refreshed during builds; a background advertising-rule updater is not implemented in this fork. The bundled snapshot and conversion report are retained so the exact tested inputs can be inspected.
