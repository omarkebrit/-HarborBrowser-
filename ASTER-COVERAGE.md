# Feature coverage

| Area | Aster implementation | Validation scope |
| --- | --- | --- |
| Browsing and navigation | Native WebKit, back/forward, reload, search, find in page | Upstream unit plan; local native navigation and URL-bar tests |
| Tabs | Upstream tab management and persistence | 25 loaded tabs, process relaunch and first/last tab access |
| Private browsing | Separate nonpersistent web data and private history handling | Native cookie/localStorage isolation and exclusion from regular history |
| Advertising protection | AdGuard Base + Mobile Ads converted to native WebKit rules during CI | Real WebKit rule compilation; controlled blocked resource and site exception |
| Tracking protection | Upstream standard/strict native lists | Upstream content-blocker unit coverage; local acceptance |
| Video and audio | Inline playback, gesture-based sound, MP4/HLS/blob/iframe, fullscreen | Original H.264/AAC fixture; decoded progressing playback, fullscreen rotation/exit, popup and autoplay behavior |
| PiP and AirPlay | Native WebKit configuration enabled | Configuration unit assertions; actual hardware/receiver remains unverified |
| Downloads | Upstream native download manager | Native file download and original content verification |
| Reader/bookmarks/reading list | Upstream implementations | Native article save, reader rendering and reading-list presence |
| Passwords and autofill | Inherited password management and credential-provider extension | Upstream unit coverage; physical Face ID and signed extension need device testing |
| Appearance and accessibility | Aster light/dark palette, original icon, scalable text | Native large-text navigation and theme switching; source palette contrast checks |
| Languages | Upstream locales with app-name updates | String syntax checked; full translation and Arabic device review remain outstanding |
| Privacy consent | Technical data, crashes, daily usage, studies and rollouts default off | Consent and independent-toggle unit coverage |
| Default browser | Apple-managed entitlement not included | Needs approval/provisioning before offering this capability |
| Account synchronization | Inherited Firefox Account provider code | Independent identifier/redirect and end-to-end service use unverified; onboarding promotion disabled |
| Brave Sync, Rewards, Wallet, Leo, News and paid VPN | Not implemented | Requires separate implementations and/or service agreements |
| Installation | Unsigned device IPA from GitHub | Compilation is verified by CI; installation needs Apple signing |

The app still makes ordinary browser requests, including requested pages, search and provider resources. Disabling usage collection does not promise zero network activity. Ad blocking depends on the current rules and site behavior; video advertising and all tracking cannot be guaranteed absent.

The checked-in starter advertising pack contains 18 domain rules. CI replaces it with the generated production pack before either testing or building. Its exact source URLs, hashes, conversion revision and rule count are recorded alongside `ads.json` in the filter artifact. Production generation fails if the converter or WebKit compilation fails.
