# Reviewing the Aster changes

The initial import is the complete, pinned upstream release described in `UPSTREAM.json`. Review Aster-specific changes against that Firefox release rather than treating every imported line as a new browser implementation.

| Change | Main entry points |
| --- | --- |
| Independent identity/configuration | `firefox-ios/Client/Configuration/{Common,Fennec,Firefox}.xcconfig`, `Client/Info.plist`, `Client/Entitlements/AsterApplication.entitlements`, `BrowserKit/Sources/Common/Constants/AppName.swift` |
| Native media capability | `firefox-ios/Client/TabManagement/TabConfigurationProvider.swift`, `BrowserKit/Sources/WebEngine/WKWebview/WKEngineConfigurationProvider.swift` and their existing tests |
| Bundled advertising layer and site exceptions | `firefox-ios/Client/ContentBlocker/`, `Settings/Main/General/AdBlockerSetting.swift`, `MainMenuViewController.swift`, `Client/Assets/AsterFilters/` |
| Production rule generation | `Scripts/aster/prepare_ad_filters.py`, `Scripts/aster/validate_ad_filters.swift` |
| Private defaults and independent consent | `Client/Experiments/Experiments.swift`, telemetry wrappers, onboarding technical toggle, settings data/studies controls, `Providers/RustSyncManager.swift` and existing tests |
| Colors/artwork | `BrowserKit/Sources/Common/Theme/`, native color tokens, asset catalogs, `branding/generate_assets.py` |
| App self-name translations | Existing `.strings` resources and `firefox-ios/Shared/Strings.swift`; actual external provider names are preserved |
| Product links/onboarding | `BrowserKit/Sources/Shared/SupportUtils.swift`, settings support/privacy/about rows, Nimbus onboarding/terms/sharing/survey defaults |
| Real UI acceptance | `firefox-ios/firefox-ios-tests/Tests/XCUITests/AsterAcceptanceTests.swift`, `scripts/aster-test-server.py`, `test-fixtures/aster/media/` |
| Native build/evidence | `.github/workflows/aster-ios.yml`, `scripts/aster-ci-prepare.sh` |

The native project registers the added resource folder and acceptance source. Internal Mozilla module and scheme names are preserved to avoid breaking the browser's build structure. Upstream service implementations are retained as upstream code, with their limitations described in the coverage and privacy documents.

Original workflows and ownership references are archived under `.github/` for provenance. Only the Aster workflow is active. The old Harbor code is preserved in its original repository history and branch.
