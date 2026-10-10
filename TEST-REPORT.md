# Aster validation report

Native execution is in progress. In [GitHub run 38071980382](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38071980382), source `a75348a9458a780a9e3b6a3e0056b0b37ba31317`, the full upstream `UnitTest` plan and simulator signing checks passed. The main UI selection executed 15 tests: 11 passed and four failed. Passing cases include actual MP4/HLS/iframe/blob decoding, private storage and history isolation, advertising blocking with exception/re-enable controls, reader/bookmarks/reading list, offline Help/Privacy, local navigation, Arabic/RTL, large text and three upstream UI cases.

In [regression run 38081888858](https://github.com/omarkebrit/-HarborBrowser-/actions/runs/38081888858), source `1a1946780b59d4e837f62d5b20acd96cbfce7499`, the real popup/player case passed. Screenshots showed real decoded fullscreen video in both orientations and manual playback after an actual `NotAllowedError`; two assertions failed because XCTest requested activation points for noninteractive media labels. The 25-tab files saved successfully, but the test-only profile reset had removed hidden system metadata at the shared-container root, causing relaunch to receive a different app-group directory. The reset now preserves that metadata, with a registered filesystem regression; media-label geometry checks are scoped to those three observed labels. The full required native run must verify these changes and the improved largest-text homepage layout. No production IPA or complete passing UI result is claimed yet.

## Local checks completed

- Native project and property-list edits reviewed; new acceptance source and advertising folder registered in Xcode.
- Python fixture-server HTTP contracts: 58 checks covering HEAD, byte ranges, suffix ranges, invalid requests, missing resources and correct payloads.
- Fixture JavaScript syntax checked with Node; original six-second media confirmed as H.264 video and AAC audio, including HLS segments.
- Localization string syntax validated, icon assets rendered with opaque 1024-pixel images, primary palette text contrast checked.
- New consent, native media configuration and advertising/safelist tests added to existing registered unit targets.
- Fullscreen hosts use frames/autoresizing and respect WebKit's entering/fullscreen/exiting ownership; registered regression tests cover repeated updates and resizing. Real native fullscreen validation remains required.

## Required native checks

- Full upstream `UnitTest` plan, including the newly added consent, media and content-blocker assertions.
- Thirteen `AsterAcceptanceTests` plus selected upstream URL-bar and night-mode UI checks on an iPhone 15 Pro Max simulator.
- Positive-control advertising exception test, original-file native download, separate private storage, 25-tab process restoration, decoded video transports, fullscreen and rotation, popup handling, restrictive autoplay, reader, bundled offline Help/Privacy, large text and Arabic/RTL navigation.
- Actual WebKit compilation of the generated advertising rules.
- Unsigned production iPhone build after the required tests pass.

GitHub retains `.xcresult` bundles, logs, summaries, screenshots and accessibility hierarchies. The filter artifact records its inputs and output. The published IPA is tied to the source commit saved in `source-commit.txt`.

## Remaining limits

No physical iPhone is attached. Signing, actual installation, Face ID, battery/performance under long sessions, AirPlay receivers and protected DRM content need device testing. No finite test suite certifies all websites or all Brave features. Inherited account services and complete Arabic translations require separate review.
