# Feature coverage

Full [run 23](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39406335775), source `4557246b64453abb464844aa8ff4358e90107c5b`, passed units 5,747/0 failed/2 upstream skips but failed preflight 3/2, blocking IPA publication; main UI is running and download/device outcomes are pending. Parallel [run 22](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39405042843), source `5174b9a6775c0a0ada40bebf7c309ee300cf1bc5`, recorded units 5,745/2 failed/2 skipped.

Media-only [diagnostic 24](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39414241881), source `e0f89e5f8ce34e6faa230dac404b5a1434712486`, and isolated-WebEngine [diagnostic 25](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/39414543028), source `1617b9a76839208c5f2ac533a646226929491787`, are running. They produce no IPA and do not replace full native validation. The next full candidate has not started. See [TEST-REPORT.md](TEST-REPORT.md) for the detailed results and permanent evidence.

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
| Video and audio | Inline playback, gesture-based sound, MP4/HLS/blob/iframe, fullscreen | Run 20 main passed all 16 cases, including actual MP4/HLS/iframe/blob iterations, ordinary fullscreen and strict first-loop boundary rotation. The same run's earlier preflight setup missed that boundary. Final original evidence confirms actual resize +233.201ms and progressing 55→109→215 decoded frames through two further landscape loops; no production fix for run 17's stall is established |
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
