# Aster validation report

Native execution is in progress. The first run compiled the native app code and the 40,675-rule production pack; an unresolved identifier in the added UI test source stopped test execution. That test identifier is now corrected. No passing simulator or device-build result is claimed before the required run completes.

## Local checks completed

- Native project and property-list edits reviewed; new acceptance source and advertising folder registered in Xcode.
- Python fixture-server HTTP contracts: 39 checks covering HEAD, byte ranges, suffix ranges, invalid requests, missing resources and correct payloads.
- Fixture JavaScript syntax checked with Node; original six-second media confirmed as H.264 video and AAC audio, including HLS segments.
- Localization string syntax validated, icon assets rendered with opaque 1024-pixel images, primary palette text contrast checked.
- New consent, native media configuration and advertising/safelist tests added to existing registered unit targets.

## Required native checks

- Full upstream `UnitTest` plan, including the newly added consent, media and content-blocker assertions.
- Twelve `AsterAcceptanceTests` plus selected upstream URL-bar and night-mode UI checks on an iPhone 15 Pro Max simulator.
- Positive-control advertising exception test, original-file native download, separate private storage, 25-tab process restoration, decoded video transports, fullscreen and rotation, popup handling, restrictive autoplay, reader, large text and Arabic/RTL navigation.
- Actual WebKit compilation of the generated advertising rules.
- Unsigned production iPhone build after the required tests pass.

GitHub retains `.xcresult` bundles, logs, summaries, screenshots and accessibility hierarchies. The filter artifact records its inputs and output. The published IPA is tied to the source commit saved in `source-commit.txt`.

## Remaining limits

No physical iPhone is attached. Signing, actual installation, Face ID, battery/performance under long sessions, AirPlay receivers and protected DRM content need device testing. No finite test suite certifies all websites or all Brave features. Inherited account services and complete Arabic translations require separate review.
