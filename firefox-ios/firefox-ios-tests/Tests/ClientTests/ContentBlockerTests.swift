// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
import Shared
@testable import Client

@MainActor
final class ContentBlockerTests: XCTestCase {
    private var featureFlags: MockNimbusFeatureFlags!
    private var profile: MockProfile!
    private var originalFetcher: AdBlockerListFetcherProtocol!

    override func setUp() async throws {
        try await super.setUp()
        featureFlags = MockNimbusFeatureFlags()
        profile = MockProfile()
        DependencyHelperMock().bootstrapDependencies(injectedFeatureFlagProvider: featureFlags)
        originalFetcher = ContentBlocker.shared.adBlockerListFetcher

        // Ensure all rules are removed from the global store prior to each test
        let expectation = XCTestExpectation()
        ContentBlocker.shared.removeAllRulesInStore {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation])
    }

    override func tearDown() async throws {
        UserDefaults.standard.removeObject(forKey: ASAdBlockerListFetcher.adBlockerRecordID)
        ContentBlocker.shared.adBlockerListFetcher = originalFetcher
        DependencyHelperMock().reset()
        featureFlags = nil
        profile = nil
        originalFetcher = nil
        try await super.tearDown()
    }

    func testCompileListsNotInStore_callsCompletionHandlerSuccessfully() async {
        let expectation = XCTestExpectation()
        ContentBlocker.shared.compileListsNotInStore {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2)
    }

    func testReloadAdBlockerList_fetchesList() async {
        let mock = MockAdBlockerListFetcher(jsonToReturn: Self.validRuleJSON)
        ContentBlocker.shared.adBlockerListFetcher = mock

        await ContentBlocker.shared.reloadAdBlockerList()

        XCTAssertEqual(mock.fetchCallCount, 1)
    }

    func testReloadAdBlockerList_whenNoListAvailable_completes() async {
        let mock = MockAdBlockerListFetcher(jsonToReturn: nil)
        ContentBlocker.shared.adBlockerListFetcher = mock

        await ContentBlocker.shared.reloadAdBlockerList()

        XCTAssertEqual(mock.fetchCallCount, 1)
    }

    func testCurrentlyEnabledLists_whenAdBlockerFlagAndPrefOn_includesAdBlockerRule() {
        featureFlags.enabledFlags = [.adBlocker]
        profile.prefs.setBool(true, forKey: PrefsKeys.BlockAds)
        let subject = FirefoxTabContentBlocker(tab: MockContentBlockerTab(), prefs: profile.prefs)

        XCTAssertTrue(subject.currentlyEnabledLists().contains(ASAdBlockerListFetcher.adBlockerRecordID))
    }

    func testCurrentlyEnabledLists_whenBlockAdsPrefOff_excludesAdBlockerRule() {
        featureFlags.enabledFlags = [.adBlocker]
        profile.prefs.setBool(false, forKey: PrefsKeys.BlockAds)
        let subject = FirefoxTabContentBlocker(tab: MockContentBlockerTab(), prefs: profile.prefs)

        XCTAssertFalse(subject.currentlyEnabledLists().contains(ASAdBlockerListFetcher.adBlockerRecordID))
    }

    func testCurrentlyEnabledLists_adBlockingDoesNotDependOnRemoteFeatureFlag() {
        featureFlags.enabledFlags = []
        profile.prefs.setBool(true, forKey: PrefsKeys.BlockAds)
        let subject = FirefoxTabContentBlocker(tab: MockContentBlockerTab(), prefs: profile.prefs)

        XCTAssertTrue(subject.currentlyEnabledLists().contains(ASAdBlockerListFetcher.adBlockerRecordID))
    }

    func testCurrentlyEnabledLists_adBlockingDefaultsOnAlongsideStandardProtection() {
        featureFlags.enabledFlags = []
        profile.prefs.setBool(true, forKey: ContentBlockingConfig.Prefs.EnabledKey)
        let subject = FirefoxTabContentBlocker(tab: MockContentBlockerTab(), prefs: profile.prefs)
        let expected = Set(BlocklistFileName.basic.map { $0.filename } + [ASAdBlockerListFetcher.adBlockerRecordID])

        XCTAssertEqual(Set(subject.currentlyEnabledLists()), expected)
    }

    func testCurrentlyEnabledLists_disablingAdsPreservesStrictProtectionAndPrivateMode() {
        profile.prefs.setBool(false, forKey: PrefsKeys.BlockAds)
        profile.prefs.setBool(true, forKey: ContentBlockingConfig.Prefs.EnabledKey)
        profile.prefs.setString(BlockingStrength.strict.rawValue, forKey: ContentBlockingConfig.Prefs.StrengthKey)
        let tab = MockContentBlockerTab()
        tab.isPrivate = true
        let subject = FirefoxTabContentBlocker(tab: tab, prefs: profile.prefs)

        XCTAssertEqual(subject.currentlyEnabledLists(), BlocklistFileName.listsForMode(strict: true))
    }

    func testBundledAdBlockerLoadsValidPhysicalRulesWithoutNetwork() async throws {
        let bundled = await BundledAdBlockerListFetcher().fetchAdBlockerListJSON()
        let encoded = try XCTUnwrap(bundled)
        let rules = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(encoded.utf8)) as? [[String: Any]])

        XCTAssertFalse(rules.isEmpty)
        XCTAssertTrue(rules.contains { ($0["action"] as? [String: Any])?["type"] as? String == "block" })
    }

    func testSafelistJSONUsesExactHostAndCannotInjectAdditionalRules() throws {
        let original = ContentBlocker.shared.safelistedDomains.domainSet
        defer { ContentBlocker.shared.safelistedDomains.domainSet = original }
        ContentBlocker.shared.safelistedDomains.domainSet = ["example.com", "unexpected\"quoted.example"]
        let fragment = ContentBlocker.shared.safelistAsJSON()
        let rules = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(("[{}" + fragment + "]").utf8)) as? [[String: Any]])
        let domains = (rules.last?["trigger"] as? [String: Any])?["if-domain"] as? [String]

        XCTAssertEqual(rules.count, 2)
        XCTAssertEqual(domains, ["example.com", "unexpected\"quoted.example"])
        XCTAssertFalse(domains?.contains("*example.com") ?? true)
    }

    func testSafelistStatsMatchOnlyTheRequestedHost() throws {
        var safelist = SafelistedDomains()
        safelist.domainSet = ["example.com"]
        let pattern = try XCTUnwrap(safelist.domainRegex.first)
        let regex = try NSRegularExpression(pattern: pattern)
        for host in ["notexample.com", "example.com.evil.test", "sub.example.com"] {
            XCTAssertNil(regex.firstMatch(in: host, range: NSRange(host.startIndex..., in: host)), host)
        }
        let host = "example.com"
        XCTAssertNotNil(regex.firstMatch(in: host, range: NSRange(host.startIndex..., in: host)))
    }

    func testCurrentlyEnabledLists_adBlockingAppliesEvenWhenTrackingProtectionOff() {
        featureFlags.enabledFlags = [.adBlocker]
        profile.prefs.setBool(false, forKey: ContentBlockingConfig.Prefs.EnabledKey)
        profile.prefs.setBool(true, forKey: PrefsKeys.BlockAds)
        let subject = FirefoxTabContentBlocker(tab: MockContentBlockerTab(), prefs: profile.prefs)

        XCTAssertEqual(subject.currentlyEnabledLists(), [ASAdBlockerListFetcher.adBlockerRecordID])
    }

    func testReloadAdBlockerList_secondCallWithSameJSON_skipsRecompile() async {
        let mock = MockAdBlockerListFetcher(jsonToReturn: Self.validRuleJSON)
        ContentBlocker.shared.adBlockerListFetcher = mock
        let hashKey = ASAdBlockerListFetcher.adBlockerRecordID

        await ContentBlocker.shared.reloadAdBlockerList()
        let hashAfterFirst = UserDefaults.standard.string(forKey: hashKey)
        XCTAssertNotNil(hashAfterFirst, "Hash should be stored after successful compile")

        await ContentBlocker.shared.reloadAdBlockerList()
        XCTAssertEqual(mock.fetchCallCount, 2, "Fetcher is called both times")
        XCTAssertEqual(
            UserDefaults.standard.string(forKey: hashKey),
            hashAfterFirst,
            "Hash unchanged — compile was skipped"
        )
    }

    func testReloadAdBlockerList_afterRemoveAllRules_recompilesEvenWithSameJSON() async {
        let mock = MockAdBlockerListFetcher(jsonToReturn: Self.validRuleJSON)
        ContentBlocker.shared.adBlockerListFetcher = mock
        let hashKey = ASAdBlockerListFetcher.adBlockerRecordID

        await ContentBlocker.shared.reloadAdBlockerList()
        XCTAssertNotNil(UserDefaults.standard.string(forKey: hashKey))

        let wipe = XCTestExpectation(description: "wipe rules")
        ContentBlocker.shared.removeAllRulesInStore { wipe.fulfill() }
        await fulfillment(of: [wipe], timeout: 5)

        XCTAssertNil(
            UserDefaults.standard.string(forKey: hashKey),
            "removeAllRulesInStore should clear the cached hash"
        )

        await ContentBlocker.shared.reloadAdBlockerList()
        XCTAssertNotNil(
            UserDefaults.standard.string(forKey: hashKey),
            "Hash should be stored again after recompile"
        )
    }

    func testClearSafelist_reloadsAdBlockerList() async {
        let mock = MockAdBlockerListFetcher(jsonToReturn: Self.validRuleJSON)
        ContentBlocker.shared.adBlockerListFetcher = mock

        await ContentBlocker.shared.reloadAdBlockerList()
        XCTAssertEqual(mock.fetchCallCount, 1)

        let clearExpectation = XCTestExpectation(description: "clearSafelist completed")
        ContentBlocker.shared.clearSafelist { clearExpectation.fulfill() }
        await fulfillment(of: [clearExpectation], timeout: 5)

        XCTAssertEqual(
            mock.fetchCallCount,
            2,
            "clearSafelist should trigger reloadAdBlockerList"
        )
    }

    func testReloadAdBlockerList_differentJSON_recompiles() async {
        let mock = MockAdBlockerListFetcher(jsonToReturn: Self.validRuleJSON)
        ContentBlocker.shared.adBlockerListFetcher = mock
        let hashKey = ASAdBlockerListFetcher.adBlockerRecordID

        await ContentBlocker.shared.reloadAdBlockerList()
        let hashAfterFirst = UserDefaults.standard.string(forKey: hashKey)
        XCTAssertNotNil(hashAfterFirst)

        mock.jsonToReturn = Self.differentRuleJSON

        await ContentBlocker.shared.reloadAdBlockerList()
        let hashAfterSecond = UserDefaults.standard.string(forKey: hashKey)
        XCTAssertNotNil(hashAfterSecond)
        XCTAssertNotEqual(hashAfterFirst, hashAfterSecond, "Different JSON should produce a new hash")
    }

    private static let validRuleJSON = """
    [{"trigger":{"url-filter":".*ads.*"},"action":{"type":"block"}}]
    """

    private static let differentRuleJSON = """
    [{"trigger":{"url-filter":".*tracker.*"},"action":{"type":"block"}}]
    """
}

private final class MockContentBlockerTab: ContentBlockerTab {
    var isPrivate = false
    func currentURL() -> URL? { return nil }
    func currentWebView() -> WKWebView? { return nil }
    func imageContentBlockingEnabled() -> Bool { return false }
}
