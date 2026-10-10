// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@MainActor
final class AsterAcceptanceTests: BaseTestCase {
    private let origin = "http://127.0.0.1:8766"
    private var toolbar: ToolbarScreen { ToolbarScreen(app: app) }
    private var tabTray: TabTrayScreen { TabTrayScreen(app: app) }

    override func setUp() async throws {
        XCUIDevice.shared.orientation = .portrait
        launchArguments += [LaunchArguments.ClearWebData,
                            LaunchArguments.EnableSessionRestore,
                            LaunchArguments.SkipAppleIntelligence]
        if name.contains("testLargeTextAndAppearanceKeepNavigationAccessible") {
            launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        if name.contains("testArabicRTLNavigationUsesLocalizedNativeControls") {
            launchArguments += ["-AppleLanguages", "(ar)", "-AppleLocale", "ar_SA"]
        }
        if name.contains("testReaderBookmarkAndReadingListPreserveOriginalArticle") {
            for feature in ["apple-summarizer-feature", "hosted-summarizer-feature"] {
                launchArguments += [LaunchArguments.LoadExperiment + "defaultEnabledOff",
                                    LaunchArguments.ExperimentFeatureName + feature]
            }
        }
        try await super.setUp()
    }

    override func tearDown() async throws {
        captureDisplay("Final display")
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "Native accessibility hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        exitFullscreenIfNeeded()
        XCUIDevice.shared.orientation = .portrait
        try await super.tearDown()
    }

    func testLocalNavigationHistoryAndFindInPage() {
        open("/navigation/one.html", expecting: "First local page ready")
        app.webViews.links["Open second local page"].firstMatch.waitAndTap()
        expectText("Second local page ready")
        toolbar.tapBackButton()
        expectText("First local page ready")
        toolbar.getForwardButtonElement().waitAndTap()
        expectText("Second local page ready")

        navigator.nowAt(BrowserTab)
        navigator.goto(FindInPage)
        let find = FindInPageScreen(app: app)
        find.waitForFindInPageBarToAppear()
        find.searchForText("AsterNeedle")
        find.assertResultsCountIsDisplayed("1 of 3")
        find.tapNextResult()
        find.assertResultsCountIsDisplayed("2 of 3")
        find.tapPreviousResult()
        find.assertResultsCountIsDisplayed("1 of 3")
        navigator.goto(BrowserTab)
        navigator.goto(LibraryPanel_History)
        let history = app.tables[AccessibilityIdentifiers.LibraryPanels.HistoryPanel.tableView]
        mozWaitForElementToExist(history.staticTexts["Aster navigation one"])
        mozWaitForElementToExist(history.staticTexts["Aster navigation two"])
        captureDisplay("Local history and navigation")
    }

    func testArabicRTLNavigationUsesLocalizedNativeControls() {
        let address = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        mozWaitForElementToExist(address)
        XCTAssertTrue(address.isHittable)
        address.waitAndTap()
        address.tapAndTypeTextWhenFocused(origin + "/navigation/one.html")
        address.typeText("\r")
        navigator.nowAt(BrowserTab)
        expectText("First local page ready")
        app.webViews.links["Open second local page"].firstMatch.waitAndTap()
        expectText("Second local page ready")

        let back = app.buttons[AccessibilityIdentifiers.Toolbar.backButton]
        let forward = app.buttons[AccessibilityIdentifiers.Toolbar.forwardButton]
        mozWaitForElementToExist(back)
        mozWaitForElementToExist(forward)
        XCTAssertEqual(back.label, "السابق")
        XCTAssertEqual(forward.label, "التالي")
        XCTAssertTrue(back.isHittable)
        XCTAssertGreaterThan(back.frame.midX, forward.frame.midX,
                             "The native navigation toolbar must mirror for Arabic")
        assertAccessibleToolbar()
        captureDisplay("Actual Arabic RTL browser navigation")
        back.waitAndTap()
        expectText("First local page ready")
        XCTAssertTrue(forward.isEnabled)
        forward.waitAndTap()
        expectText("Second local page ready")
        toolbar.tapOnTabsButton()
        tabTray.assertCellExists(named: "Aster navigation two")
        captureDisplay("Actual Arabic RTL tab tray")
        tabTray.tapOnCell(named: "Aster navigation two")
        navigator.nowAt(BrowserTab)
        expectText("Second local page ready")
        XCTAssertTrue(address.isHittable)
        assertAccessibleToolbar()
    }

    func testTwentyFiveTabsSurviveProcessRelaunch() {
        open("/tab.html?number=1", expecting: "Local tab 1 ready")
        for number in 2...25 {
            newTab()
            open("/tab.html?number=\(number)", expecting: "Local tab \(number) ready")
        }
        toolbar.assertTabsButtonValue(expectedCount: "25")
        captureDisplay("Twenty five loaded tabs")
        app.launchArguments.removeAll { $0 == LaunchArguments.ClearWebData }
        forceCloseAndRelaunchApp()
        expectText("Local tab 25 ready", timeout: 20)
        toolbar.assertTabsButtonValue(expectedCount: "25")

        toolbar.tapOnTabsButton()
        let first = app.collectionViews[AccessibilityIdentifiers.TabTray.collectionView]
            .cells.matching(NSPredicate(format: "label BEGINSWITH %@", "Aster tab 1.")).firstMatch
        let exactFirst = app.collectionViews[AccessibilityIdentifiers.TabTray.collectionView].cells["Aster tab 1"]
        for _ in 0..<12 where !first.isHittable && !exactFirst.isHittable {
            app.collectionViews[AccessibilityIdentifiers.TabTray.collectionView].swipeDown()
        }
        tabTray.tapOnCell(named: "Aster tab 1")
        navigator.nowAt(BrowserTab)
        expectText("Local tab 1 ready")
        toolbar.assertTabsButtonValue(expectedCount: "25")
        captureDisplay("Restored first tab")
    }

    func testPrivateStorageAndHistoryAreIsolated() {
        open("/storage.html?mode=regular", expecting: "No saved browser session")
        app.webViews.buttons["Save regular session"].waitAndTap()
        expectText("Browser session regular with matching storage")
        newTab()
        open("/storage.html?mode=regular", expecting: "Browser session regular with matching storage")

        toolbar.tapOnTabsButton()
        tabTray.switchToPrivateBrowsing()
        tabTray.tapOnNewTabButton()
        userState.isPrivate = true
        navigator.nowAt(NewTabScreen)
        open("/storage.html?mode=private", expecting: "No saved browser session")
        app.webViews.buttons["Save private session"].waitAndTap()
        expectText("Browser session private with matching storage")
        newTab()
        open("/storage.html?mode=private", expecting: "Browser session private with matching storage")
        captureDisplay("Isolated private browser storage")

        toolbar.tapOnTabsButton()
        tabTray.switchToRegularBrowsing()
        tabTray.tapOnNewTabButton()
        userState.isPrivate = false
        navigator.nowAt(NewTabScreen)
        open("/storage.html?mode=regular", expecting: "Browser session regular with matching storage")
        let address = app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField]
        XCTAssertFalse((address.value as? String ?? "").contains("mode=private"))
        navigator.goto(LibraryPanel_History)
        let history = app.tables[AccessibilityIdentifiers.LibraryPanels.HistoryPanel.tableView]
        mozWaitForElementToExist(history.staticTexts["Aster regular browser state"])
        XCTAssertFalse(history.staticTexts["Aster private browser state"].exists,
                       "Private page titles must not enter regular history")
        captureDisplay("Regular history excludes private page")
    }

    func testNativeDownloadPreservesFixtureFile() {
        open("/downloads.html", expecting: "Aster download acceptance")
        app.webViews.links["Download Aster fixture"].firstMatch.waitAndTap()
        let download = app.tables["Context Menu"].buttons[StandardImageIdentifiers.Large.download]
        mozWaitForElementToExist(download)
        download.waitAndTap()
        waitForTabsButton()
        navigator.nowAt(BrowserTab)
        navigator.goto(LibraryPanel_Downloads)
        let downloads = app.tables["DownloadsTable"]
        mozWaitForElementToExist(downloads.staticTexts["aster-payload.txt"], timeout: 20)
        mozWaitForElementToExist(downloads.staticTexts["95 bytes"])
        captureDisplay("Native downloaded original file")
    }

    func testMP4HLSIframeAndBlobPlayRealAudioAndVideo() {
        for transport in ["mp4", "hls", "iframe", "blob"] {
            open("/media/\(transport).html", expecting: "Ready for playback", timeout: 20)
            app.webViews.buttons["Play test media"].firstMatch.waitAndTap()
            expectText("Audio and video playing", timeout: 15)
            captureDisplay("Decoded \(transport) video with audio")
        }
    }

    func testElementFullscreenKeepsPlayingAcrossRotationAndExits() {
        defer { exitFullscreenIfNeeded(); XCUIDevice.shared.orientation = .portrait }
        open("/media/fullscreen.html", expecting: "Waiting for fullscreen")
        app.webViews.buttons["Enter fullscreen"].waitAndTap()
        expectText("Fullscreen video playing in portrait", timeout: 15)
        captureDisplay("Actual portrait fullscreen video")
        XCUIDevice.shared.orientation = .landscapeLeft
        expectText("Fullscreen video playing in landscape", timeout: 15)
        captureDisplay("Actual landscape fullscreen video")
        let exit = app.webViews.buttons["Exit fullscreen"].firstMatch
        mozWaitForElementToExist(exit)
        XCTAssertTrue(exit.isHittable)
        exit.waitAndTap()
        expectText("Fullscreen exited")
        XCUIDevice.shared.orientation = .portrait
        toolbar.assertToolbarIsVisible()
        captureDisplay("Fullscreen exit restores browser controls")
    }

    func testAutomaticPopupBlockedAndUserPlayerWindowAllowed() {
        open("/popup.html", expecting: "Automatic popup attempted")
        idle(for: 1.5)
        toolbar.assertTabsButtonValue(expectedCount: "1")
        XCTAssertFalse(app.webViews.staticTexts["Unsolicited popup opened"].exists)
        app.webViews.buttons["Open player window"].waitAndTap()
        expectText("Ready for playback", timeout: 20)
        toolbar.assertTabsButtonValue(expectedCount: "2")
        app.webViews.buttons["Play test media"].waitAndTap()
        expectText("Audio and video playing", timeout: 15)
        captureDisplay("Genuine gesture opened playing video tab")
    }

    func testBlockedAutoplayStillAllowsUserPlaybackWithSound() {
        navigator.goto(AutoplaySettings)
        let blocked = app.tables.firstMatch.cells[AccessibilityIdentifiers.Settings.Autoplay.blockAudioAndVideo]
        blocked.waitAndTap()
        waitForPredicate("selected == true", element: blocked)
        navigator.goto(NewTabScreen)
        newTab()
        navigator.openURL(origin + "/media/autoplay.html")
        navigator.nowAt(BrowserTab)
        let blockedStatus = app.webViews.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Automatic playback blocked")
        ).firstMatch
        mozWaitForElementToExist(blockedStatus, timeout: 15)
        XCTAssertFalse(app.webViews.staticTexts["Audio and video playing"].exists)
        app.webViews.buttons["Play test media"].waitAndTap()
        expectText("Audio and video playing", timeout: 15)
        captureDisplay("User gesture plays sound under restrictive autoplay")
    }

    func testReaderBookmarkAndReadingListPreserveOriginalArticle() {
        open("/article.html", expecting: "Aster Reading Test Article")
        bookmark()
        navigator.nowAt(BrowserTab)
        navigator.goto(LibraryPanel_Bookmarks)
        LibraryScreen(app: app).assertBookmarkExists(named: "Aster Reading Test Article")
        app.tables["Bookmarks List"].staticTexts["Aster Reading Test Article"].waitAndTap()
        navigator.nowAt(BrowserTab)
        expectText("Aster Reading Test Article")
        mozWaitForElementToExist(app.buttons["Reader View"], timeout: 20)
        app.buttons["Reader View"].waitAndTap()
        expectText("Reader keeps the original Aster article text.", timeout: 20)
        mozWaitForElementToExist(app.buttons["Add to Reading List"])
        app.buttons["Add to Reading List"].waitAndTap()
        captureDisplay("Original article in native reader mode")
        navigator.nowAt(BrowserTab)
        navigator.goto(LibraryPanel_ReadingList)
        mozWaitForElementToExist(app.tables["ReadingTable"].staticTexts["Aster Reading Test Article"])
        captureDisplay("Original article saved for reading")
    }

    func testLargeTextAndAppearanceKeepNavigationAccessible() {
        captureDisplay("Aster home at accessibility text size")
        open("/navigation/one.html", expecting: "First local page ready")
        assertAccessibleToolbar()
        navigator.goto(DisplaySettings)
        let settings = SettingScreen(app: app)
        settings.selectDarkTheme()
        settings.assertDarkThemeSelected()
        captureDisplay("Calm dark appearance at accessibility text size")
        navigator.goto(BrowserTab)
        expectText("First local page ready")
        assertAccessibleToolbar()
        captureDisplay("Dark browser with large text")
        navigator.goto(DisplaySettings)
        settings.selectLightTheme()
        settings.assertLightThemeSelected()
        navigator.goto(BrowserTab)
        app.webViews.links["Open second local page"].firstMatch.waitAndTap()
        expectText("Second local page ready")
        assertAccessibleToolbar()
        captureDisplay("Light browser with large text")
    }

    func testNativeShieldsBlockTrackerAndHonorSiteException() {
        open("/shields.html", expecting: "Allowed script ran")
        expectText("Tracker blocked", timeout: 20)
        XCTAssertFalse(app.webViews.staticTexts["Tracker script ran"].exists)
        captureDisplay("Native shields blocked controlled tracker")
        setSiteProtection(enabled: false)
        expectText("Allowed script ran", timeout: 20)
        expectText("Tracker script ran", timeout: 20)
        captureDisplay("Explicit site exception allows controlled tracker")
        setSiteProtection(enabled: true)
        expectText("Allowed script ran", timeout: 20)
        expectText("Tracker blocked", timeout: 20)
        XCTAssertFalse(app.webViews.staticTexts["Tracker script ran"].exists)
        captureDisplay("Reenabled native shields block tracker again")
    }

    private func open(_ path: String, expecting text: String, timeout: TimeInterval = 10) {
        navigator.openURL(origin + path)
        navigator.nowAt(BrowserTab)
        expectText(text, timeout: timeout)
    }

    private func newTab() {
        toolbar.openNewTabFromTabTray()
        navigator.nowAt(NewTabScreen)
    }

    private func expectText(_ text: String, timeout: TimeInterval = 10,
                            file: StaticString = #filePath, line: UInt = #line) {
        let element = app.webViews.staticTexts[text].firstMatch
        guard element.waitForExistence(timeout: timeout) else {
            XCTFail("Missing rendered page text: \(text)", file: file, line: line)
            return
        }
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [visible], timeout: min(timeout, 5)), .completed,
                       "Page text exists but is not visible: \(text)", file: file, line: line)
    }

    private func captureDisplay(_ title: String) {
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = title
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func waitForPredicate(_ predicate: String, element: XCUIElement) {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate(format: predicate), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 10), .completed,
                       "Native control state did not settle: \(predicate)")
    }

    private func assertAccessibleToolbar() {
        for identifier in [AccessibilityIdentifiers.Toolbar.tabsButton,
                           AccessibilityIdentifiers.Toolbar.settingsMenuButton] {
            let button = app.buttons[identifier]
            mozWaitForElementToExist(button)
            XCTAssertTrue(button.isHittable)
            XCTAssertFalse(button.label.isEmpty)
            XCTAssertGreaterThanOrEqual(button.frame.width, 40)
            XCTAssertGreaterThanOrEqual(button.frame.height, 40)
        }
    }

    private func setSiteProtection(enabled: Bool) {
        toolbar.tapSettingsMenuButton()
        MainMenuScreen(app: app).tapSiteProtections()
        let toggle = app.switches[AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.toggleSwitch]
        mozWaitForElementToExist(toggle)
        XCTAssertEqual(toggle.value as? String, enabled ? "0" : "1")
        toggle.waitAndTap()
        waitForPredicate("value == '\(enabled ? "1" : "0")'", element: toggle)
        app.buttons[AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.closeButton].waitAndTap()
        navigator.nowAt(BrowserTab)
        toolbar.tapReloadButton()
    }

    private func exitFullscreenIfNeeded() {
        let exit = app.webViews.buttons["Exit fullscreen"].firstMatch
        if exit.exists && exit.isHittable { exit.tap() }
        let done = app.buttons["Done"].firstMatch
        if done.exists && done.isHittable && !app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].isHittable {
            done.tap()
        }
    }
}
