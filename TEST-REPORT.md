# Aster validation report

Validation is in progress as of 13 October 2026. The repository is now public, and [GitHub run 38086721963, attempt 3](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38086721963/attempts/3) is in progress for native-code candidate `ae128811a91010fa972eba2849635d289e9b8e78`. Native job `115207813795` has started actual execution. No completed native-validation result is claimed for this attempt, and no production iPhone IPA has been built or published.

The original attempt and attempt 2 were blocked before job steps by GitHub billing/spending-limit annotations. Attempt 2 on 13 October, job `115199420290`, produced zero steps and zero artifacts. After the owner made the repository public, attempt 3 started. Those blocked attempts add no native test or packaging result.

Publication is complete. The existing repository's branches and history, including the earlier Harbor browser project, are public. The publication review covered the 34 commits then available; no actual credential or unrelated private project was detected. Publication and its review are separate from native execution. See [BUILD-INSTALL.md](BUILD-INSTALL.md) for the current public build and installation path.

The last completed native test evidence is [GitHub run 38083870485](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38083870485), source `51fe284ead04c0d17b55c51725aa590dd951d031`. That run passed the full upstream `UnitTest` plan and all four preflight regression cases. Its main UI selection passed 14 of 15 tests; the fullscreen test failed at the toolbar hit-target assertion after exiting fullscreen and rotating back to portrait. The required download test, download byte verification and device release build were not reached.

The executed environment was Xcode 26.5 (17F42), iOS 26.5 (23F77), on the iPhone 15 Pro Max simulator. The runner was standard `macos-26`.

## Recorded native results

| Check | Run 38083870485 result | Evidence and limit |
| --- | --- | --- |
| Dependency and filter preparation | Passed | Pinned dependencies prepared; real WebKit compiled 40,723 converted AdGuard Base + Mobile Ads rules. Filter metadata records the source hashes and converter revision. |
| Four media/session preflight regressions | 4 passed, 0 failed | Automatic popup blocking/user-opened player, blocked autoplay followed by manual playback, fullscreen rotation/exit, and 25-tab process restoration all passed in this preflight invocation. |
| Full upstream `UnitTest` plan | Passed | `unit-tests.log` ends with `TEST SUCCEEDED`; includes registered Aster changes and the profile-reset filesystem regression. |
| Main local acceptance and selected upstream UI tests | 14 passed, 1 failed | Twelve Aster acceptance cases and three upstream URL-bar/night-mode cases executed. Fullscreen failed at the post-rotation toolbar assertion; the selection ended with `TEST FAILED`. |
| Dedicated native download acceptance | Not executed | Configured as a separate invocation after the main selection; the preceding failure prevented it from starting. |
| Exact downloaded-file byte verification | Not executed | No passing native download or payload-integrity result is available from this run. |
| Unsigned iPhone release build and packaging | Not executed | The workflow requires all native checks to pass before the device build. No IPA artifact was produced. |

Passing main-selection cases exercised local navigation/history/find in page; cookie/localStorage separation and private-history exclusion; advertising blocking with site exception and re-enable controls; reader/bookmark/reading-list behavior; offline Help/Privacy navigation through Settings; Arabic/RTL controls; large text and appearance; real MP4/HLS/iframe/blob playback; popup and autoplay behavior; 25 loaded tabs across process relaunch; and the selected upstream URL-bar and night-mode checks. These are bounded simulator results for the recorded source, rather than certification of every implementation path or website.

## Fullscreen failure and unverified follow-up

The main-selection recording reached real portrait and landscape fullscreen playback, tapped the fullscreen exit control, and observed the page's “Fullscreen exited” status. Immediately after the return to portrait, `ToolbarScreen.swift:47` reported that the settings/menu button was not hittable. The same test had passed in the earlier preflight invocation of this run. This records an intermittent post-rotation hit-target failure; it does not establish that every fullscreen exit restores usable browser controls.

Commit `ae128811a91010fa972eba2849635d289e9b8e78` changes only the acceptance test: it waits for both native toolbar buttons to exist and become hittable, retains the toolbar assertion, and adds actual menu → Settings → browser interaction after fullscreen exit. That follow-up is being verified in attempt 3 of run 38086721963. Its completed native result is not yet available, so its effect remains unverified and the earlier failing result remains outstanding.

## Retained advertising snapshot

The checked-in pack is the exact snapshot tested and WebKit-compiled in run 38083870485: 40,723 rules, SHA-256 `3036112f5339915d24298fcbcd241f44b3a2f6b53e7ab4090ae2924f179f3ce3`. Its metadata, raw sources, converter revision and licenses are bundled in `firefox-ios/Client/Assets/AsterFilters/`. All recorded source/rule hashes were verified after downloading the artifact. The converter report records `errorsCount: 89` for unsupported source inputs and `discardedSafariRules: 0`; this is not a claim that every AdGuard rule is supported. Real WebKit compilation passed.

## Earlier local checks

Earlier local verification recorded 58 fixture-server HTTP contract checks covering HEAD, byte ranges, suffix ranges, invalid requests, missing resources and correct payloads. Fixture JavaScript syntax was checked with Node; the original six-second media fixture was confirmed as H.264 video with AAC audio, including HLS segments. Localization string syntax, opaque icon assets and primary palette text contrast were checked. New native source/resources and unit assertions were registered in the Xcode project.

These checks complement native execution. They do not replace the unexecuted download test, iPhone release compilation, signed installation or physical-device testing.

## Checks still required

- Complete the active native workflow for the exact candidate commit and record its results.
- Pass the four preflight regressions, full upstream unit plan and all 15 main-selection UI cases, including the strengthened fullscreen recovery interaction.
- Execute and pass the separate native download case and exact payload-byte verification.
- Complete the unsigned iPhone release build and packaging, then verify the artifact against its recorded source commit.
- Supply valid Apple signing and matching provisioning for the app and all six extensions before installation; TestFlight also requires the Apple Developer/App Store Connect setup. No signing credentials are configured.
- Test the signed app on a physical iPhone 15 Pro Max. No physical-device execution or installation result is available.

Selected unmodified screenshots and their source manifest are retained in [the native gallery](docs/aster-screenshots/README.md).

Run 38083870485 retained native evidence and generated filter artifacts in GitHub; the downloaded evidence includes logs and test attachments. The first two attempts of run 38086721963 produced no executed steps or artifacts; attempt 3 has started and is still in progress. No `Aster-iPhone-UNSIGNED-needs-signing` artifact is available yet. The artifact will be published only after all required checks and device packaging pass.

## Feature and validation limits

Aster is an independent native browser based on Firefox for iOS. It does not implement all Brave features or claim identical parity. Inherited blocking of known fingerprinter URLs is present, but Brave-style canvas/audio fingerprint randomization is not integrated. No dedicated cookie-banner filter or automatic consent-rejection feature is implemented. There is no user-facing strict HTTPS-only mode; inherited automatic HTTPS upgrades are feature-gated on iOS 18.2+ and permit HTTP fallback, with release-channel defaults off and developer/beta defaults on. Real HTTPS upgrade/fallback network behavior remains unverified.

Brave Playlist and a saved-media background-playback library, Brave Sync, Rewards, Wallet, Leo, News and paid VPN services are not implemented. Firefox Account integration remains inherited provider code whose independent identifiers, redirects and end-to-end use are unverified. The Apple-managed default-browser entitlement is not included. Advertising rules are refreshed during builds; this fork does not provide a background advertising-rule updater. Protection depends on the bundled lists and website behavior; no result promises removal of all advertising or tracking.

PiP and AirPlay are enabled in native WebKit configuration, with configuration-level unit assertions; actual PiP/device behavior and AirPlay receivers remain unverified. Simulator decoding of an AAC track is not evidence of audible sound on a physical iPhone. Signed credential extensions, Face ID, protected DRM streams, long-session battery/performance, background audio behavior, complete Arabic translations and accessibility on a physical device require further testing. The latest native run used an iPhone 15 Pro Max simulator and does not certify every supported iOS version. No finite test suite certifies all websites or every browser feature.
