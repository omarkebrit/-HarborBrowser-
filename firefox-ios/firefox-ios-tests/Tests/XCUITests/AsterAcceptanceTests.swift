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

    private struct FullscreenMediaClock: Decodable {
        let t: TimeInterval
        let duration: TimeInterval
        let rate: Double
        let playing: Bool
        let epochMs: Double
        let playRequestedEpochMs: Double
        let totalNaturalWraps: Int
        let orientation: String
    }

    private struct FullscreenRotationObservation: Decodable {
        let t: TimeInterval
        let duration: TimeInterval
        let epochMs: Double
        let totalNaturalWraps: Int
    }

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
        let documentReadinessTimeout: TimeInterval = 30
        open("/tab.html?number=1", expecting: "Local tab 1 ready", documentTimeout: documentReadinessTimeout)
        for number in 2...25 {
            newTab()
            open("/tab.html?number=\(number)", expecting: "Local tab \(number) ready",
                 documentTimeout: documentReadinessTimeout)
            toolbar.assertTabsButtonValue(expectedCount: "\(number)")
        }
        toolbar.assertTabsButtonValue(expectedCount: "25")
        captureDisplay("Twenty five loaded tabs")
        app.launchArguments.removeAll { $0 == LaunchArguments.ClearWebData }
        forceCloseAndRelaunchApp()
        expectText("Local tab 25 ready", timeout: 20, documentTimeout: documentReadinessTimeout)
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
        expectText("Local tab 1 ready", documentTimeout: documentReadinessTimeout)
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
            expectMediaText("Audio and video playing", timeout: 15)
            captureDisplay("Decoded \(transport) video with audio")
        }
    }

    func testElementFullscreenKeepsPlayingAcrossRotationAndExits() {
        defer { exitFullscreenIfNeeded(); XCUIDevice.shared.orientation = .portrait }
        open("/media/fullscreen.html", expecting: "Waiting for fullscreen")
        app.webViews.buttons["Enter fullscreen"].waitAndTap()
        expectMediaText("Fullscreen video playing in portrait", timeout: 15)
        captureDisplay("Actual portrait fullscreen video")
        XCUIDevice.shared.orientation = .landscapeLeft
        expectMediaText("Fullscreen video playing in landscape", timeout: 15)
        captureDisplay("Actual landscape fullscreen video")
        expectMediaText("Fullscreen loop playback verified in landscape", timeout: 20)
        captureDisplay("Decoded fullscreen frames continue after two landscape loops")
        let exit = app.webViews.buttons["Exit fullscreen"].firstMatch
        mozWaitForElementToExist(exit)
        XCTAssertTrue(exit.isHittable)
        exit.waitAndTap()
        expectText("Fullscreen exited")
        XCUIDevice.shared.orientation = .portrait
        for identifier in [AccessibilityIdentifiers.Toolbar.settingsMenuButton,
                           AccessibilityIdentifiers.Toolbar.tabsButton] {
            waitForPredicate("exists == true AND hittable == true", element: app.buttons[identifier])
        }
        toolbar.assertToolbarIsVisible()
        captureDisplay("Fullscreen exit restores browser controls")
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].waitAndTap()
        let settings = app.tables.cells[AccessibilityIdentifiers.MainMenu.settings].firstMatch
        waitForPredicate("exists == true AND hittable == true", element: settings)
        captureDisplay("Recovered native browser menu accepts interaction")
        settings.waitAndTap()
        mozWaitForElementToExist(app.tables[AccessibilityIdentifiers.Settings.tableViewController])
        app.buttons[AccessibilityIdentifiers.Settings.navigationBarItem].waitAndTap()
        navigator.nowAt(BrowserTab)
        expectText("Fullscreen exited")
    }

    func testElementFullscreenKeepsPlayingWhenFirstLoopBoundaryMeetsRotation() {
        defer { exitFullscreenIfNeeded(); XCUIDevice.shared.orientation = .portrait }
        open("/media/fullscreen.html", expecting: "Waiting for fullscreen")
        app.webViews.buttons["Enter fullscreen"].waitAndTap()
        expectMediaText("Fullscreen video playing in portrait", timeout: 15)
        guard let firstBoundary = rotateAtFirstFullscreenLoopBoundary() else { return }
        expectMediaText("Fullscreen first-loop boundary rotation observed", timeout: 15)
        let prefix = "Aster rotation observation "
        let observation = app.webViews.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", prefix)
        ).firstMatch.label
        let resizeEvidence = XCTAttachment(string: observation)
        resizeEvidence.name = "First actual landscape resize at the first loop boundary"
        resizeEvidence.lifetime = .keepAlways
        add(resizeEvidence)
        guard observation.hasPrefix(prefix),
              let data = String(observation.dropFirst(prefix.count)).data(using: .utf8),
              let resize = try? JSONDecoder().decode(FullscreenRotationObservation.self, from: data),
              resize.t.isFinite, resize.duration.isFinite, resize.epochMs.isFinite,
              resize.t >= 0, resize.t <= resize.duration, (5.9...6.1).contains(resize.duration) else {
            XCTFail("Invalid actual landscape resize observation: \(observation)")
            return
        }
        let resizeOffset = resize.epochMs / 1000 - firstBoundary
        let actualTiming = XCTAttachment(string: "\(observation)\nfirstBoundaryEpochMs=\(firstBoundary * 1000)\n"
            + "actualResizeOffsetSeconds=\(resizeOffset)")
        actualTiming.name = "Actual landscape resize offset from the predicted first loop boundary"
        actualTiming.lifetime = .keepAlways
        add(actualTiming)
        XCTAssertTrue((-0.75...0.5).contains(resizeOffset),
                      "Actual landscape resize missed the first boundary: offset=\(resizeOffset), \(observation)")
        XCTAssertTrue((0...1).contains(resize.totalNaturalWraps),
                      "Actual landscape resize happened after the first loop: \(observation)")
        expectMediaText("Fullscreen video playing in landscape", timeout: 15)
        captureDisplay("Actual first-loop boundary landscape fullscreen video")
        expectMediaText("Fullscreen loop playback verified in landscape", timeout: 20)
        captureDisplay("Decoded fullscreen frames continue after two boundary-targeted landscape loops")
        let exit = app.webViews.buttons["Exit fullscreen"].firstMatch
        mozWaitForElementToExist(exit)
        XCTAssertTrue(exit.isHittable)
        exit.waitAndTap()
        expectText("Fullscreen exited")
        XCUIDevice.shared.orientation = .portrait
        for identifier in [AccessibilityIdentifiers.Toolbar.settingsMenuButton,
                           AccessibilityIdentifiers.Toolbar.tabsButton] {
            waitForPredicate("exists == true AND hittable == true", element: app.buttons[identifier])
        }
        toolbar.assertToolbarIsVisible()
        captureDisplay("Boundary rotation exit restores browser controls")
        app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton].waitAndTap()
        let settings = app.tables.cells[AccessibilityIdentifiers.MainMenu.settings].firstMatch
        waitForPredicate("exists == true AND hittable == true", element: settings)
        captureDisplay("Recovered native browser menu accepts interaction after boundary rotation")
        settings.waitAndTap()
        mozWaitForElementToExist(app.tables[AccessibilityIdentifiers.Settings.tableViewController])
        app.buttons[AccessibilityIdentifiers.Settings.navigationBarItem].waitAndTap()
        navigator.nowAt(BrowserTab)
        expectText("Fullscreen exited")
    }

    func testAutomaticPopupBlockedAndUserPlayerWindowAllowed() {
        open("/popup.html", expecting: "Automatic popup attempted")
        idle(for: 1.5)
        toolbar.assertTabsButtonValue(expectedCount: "1")
        XCTAssertFalse(app.webViews.staticTexts["Unsolicited popup opened"].exists)
        app.webViews.buttons["Open player window"].waitAndTap()
        expectPopupText("Ready for playback", timeout: 20)
        toolbar.assertTabsButtonValue(expectedCount: "2")
        let play = app.webViews.buttons["Play test media"].firstMatch
        mozWaitForElementToExist(play)
        XCTAssertTrue(app.webViews["contentView"].firstMatch.frame.contains(play.frame))
        play.tap(force: true)
        expectPopupText("Audio and video playing", timeout: 15)
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
        let blockedStatus = app.webViews.staticTexts["Automatic playback blocked: NotAllowedError"].firstMatch
        mozWaitForElementToExist(blockedStatus, timeout: 15)
        let diagnostic = app.webViews.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Frames: ")
        ).firstMatch
        mozWaitForElementToExist(diagnostic)
        XCTAssertTrue(diagnostic.label.contains("paused: true"))
        XCTAssertTrue(diagnostic.label.contains("time: 0.00"))
        XCTAssertTrue(diagnostic.label.contains("automatic result: NotAllowedError"))
        XCTAssertFalse(app.webViews.staticTexts["Audio and video playing"].exists)
        captureDisplay("Real automatic playback attempt remains paused")
        app.webViews.buttons["Play test media"].waitAndTap()
        expectMediaText("Audio and video playing", timeout: 15)
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

    func testBundledPrivacyAndHelpAreAccessibleFromSettings() {
        open("/navigation/one.html", expecting: "First local page ready")
        navigator.goto(SettingsScreen)
        guard tapSettingsCell(AccessibilityIdentifiers.Settings.PrivacyPolicy.title) else { return }
        expectText("Aster privacy information")
        expectText("Browser data")
        let privacyDescription = app.webViews.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Aster is an independent browser built from Firefox for iOS.")
        ).firstMatch
        mozWaitForElementToExist(privacyDescription)
        waitForPredicate("hittable == true", element: privacyDescription)
        XCTAssertTrue(privacyDescription.label.contains("It is not operated by Mozilla or Brave."))
        captureDisplay("Bundled privacy notice through native Settings")

        navigationControllerBackAction(for: app)()
        mozWaitForElementToExist(app.tables[AccessibilityIdentifiers.Settings.tableViewController])
        guard tapSettingsCell(AccessibilityIdentifiers.Settings.Help.title) else { return }
        expectText("Aster Help")
        expectText("Browse and navigate")
        let helpDescription = app.webViews.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", "Aster is an independent browser built from Firefox for iOS.")
        ).firstMatch
        mozWaitForElementToExist(helpDescription)
        waitForPredicate("hittable == true", element: helpDescription)
        XCTAssertTrue(helpDescription.label.contains(
            "This Help page is stored on your device and can be read offline."
        ))
        captureDisplay("Bundled offline help through native Settings")

        navigationControllerBackAction(for: app)()
        app.buttons[AccessibilityIdentifiers.Settings.navigationBarItem].waitAndTap()
        navigator.nowAt(BrowserTab)
        expectText("First local page ready")
        toolbar.assertTabsButtonValue(expectedCount: "1")
        assertAccessibleToolbar()
        captureDisplay("Native dismissal preserves original browser tab")
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

    private func open(_ path: String, expecting text: String, timeout: TimeInterval = 10,
                      documentTimeout: TimeInterval? = nil) {
        navigator.openURL(origin + path)
        navigator.nowAt(BrowserTab)
        expectText(text, timeout: timeout, documentTimeout: documentTimeout)
    }

    private func newTab() {
        let tabs = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
        waitForPredicate("exists == true && hittable == true", element: tabs)
        guard let value = tabs.value as? String, let count = Int(value) else {
            XCTFail("The native tab counter must report its current count before creation")
            return
        }
        tabs.tap()
        let trayButton = app.buttons[AccessibilityIdentifiers.TabTray.newTabButton]
        let commandImage = userState.isPrivate ? StandardImageIdentifiers.Large.privateMode
            : StandardImageIdentifiers.Large.plus
        let menuButton = app.tables["Context Menu"].buttons[commandImage]
        let creationChoice = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            trayButton.exists || menuButton.exists
        }, object: app)
        XCTAssertEqual(XCTWaiter().wait(for: [creationChoice], timeout: 15), .completed,
                       "A visible native new-tab command must appear")
        if trayButton.exists {
            let collection = app.collectionViews[AccessibilityIdentifiers.TabTray.collectionView]
            waitForPredicate("exists == true", element: collection)
            waitForPredicate("exists == true && hittable == true", element: trayButton)
            trayButton.tap()
        } else {
            waitForPredicate("exists == true && hittable == true", element: menuButton)
            captureDisplay("Native tab actions menu supplies the new-tab command")
            menuButton.tap()
        }
        toolbar.assertTabsButtonValue(expectedCount: "\(count + 1)")
        navigator.nowAt(NewTabScreen)
    }

    private func expectText(_ text: String, timeout: TimeInterval = 10,
                            documentTimeout: TimeInterval? = nil,
                            file: StaticString = #filePath, line: UInt = #line) {
        let element = app.webViews.staticTexts.matching(NSPredicate(format: "label == %@", text)).firstMatch
        guard element.waitForExistence(timeout: documentTimeout ?? timeout) else {
            XCTFail("Missing rendered page text: \(text)", file: file, line: line)
            return
        }
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [visible], timeout: timeout), .completed,
                       "Page text exists but is not visible: \(text)", file: file, line: line)
    }

    // Native screenshots prove these media labels render despite XCTest activation-point errors.
    private func expectMediaText(_ text: String, timeout: TimeInterval,
                                 file: StaticString = #filePath, line: UInt = #line) {
        let element = app.webViews.staticTexts.matching(NSPredicate(format: "label == %@", text)).firstMatch
        guard element.waitForExistence(timeout: timeout) else {
            XCTFail("Missing rendered media text: \(text)", file: file, line: line)
            return
        }
        let viewport = app.webViews["contentView"].firstMatch
        let visible = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            let frame = element.frame
            return frame.minX.isFinite && frame.minY.isFinite && frame.width.isFinite && frame.height.isFinite
                && frame.width > 0 && frame.height > 0 && viewport.frame.contains(frame)
                && self.app.windows.firstMatch.frame.contains(frame)
        }, object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [visible], timeout: timeout), .completed,
                       "Media text must render inside the native viewport and display: \(text)", file: file, line: line)
    }

    private func rotateAtFirstFullscreenLoopBoundary(file: StaticString = #filePath, line: UInt = #line) -> TimeInterval? {
        let prefix = "Aster media clock "
        let raw = app.webViews.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH %@", prefix)
        ).firstMatch.label
        let receivedAt = Date().timeIntervalSince1970
        guard raw.hasPrefix(prefix),
              let data = String(raw.dropFirst(prefix.count)).data(using: .utf8),
              let clock = try? JSONDecoder().decode(FullscreenMediaClock.self, from: data) else {
            XCTFail("SETUP: Missing or invalid first-loop media clock: \(raw)", file: file, line: line)
            return nil
        }
        let sampleAt = clock.epochMs / 1000
        let playRequestedAt = clock.playRequestedEpochMs / 1000
        let age = receivedAt - sampleAt
        guard clock.t.isFinite, clock.duration.isFinite, clock.rate.isFinite, clock.epochMs.isFinite,
              clock.playRequestedEpochMs.isFinite,
              clock.t >= 0, clock.t < clock.duration, (5.9...6.1).contains(clock.duration), clock.rate > 0,
              clock.playing, clock.orientation == "portrait", clock.totalNaturalWraps == 0,
              sampleAt >= playRequestedAt, sampleAt - playRequestedAt < clock.duration / clock.rate,
              age >= 0, age <= 1.5 else {
            XCTFail("SETUP: First-loop clock must be fresh, playing in portrait, and before its first wrap; age=\(age), \(raw)",
                    file: file, line: line)
            return nil
        }
        let firstBoundary = sampleAt + (clock.duration - clock.t) / clock.rate
        let target = firstBoundary - 0.4
        let waitDuration = target - Date().timeIntervalSince1970
        guard waitDuration > 0, waitDuration <= min(6.1, clock.duration / clock.rate) else {
            XCTFail("SETUP: Too late to target the first loop boundary; target=\(target), wait=\(waitDuration), \(raw)",
                    file: file, line: line)
            return nil
        }
        let targetReached = XCTestExpectation(description: "First loop boundary rotation target")
        DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + waitDuration) {
            targetReached.fulfill()
        }
        guard XCTWaiter().wait(for: [targetReached], timeout: waitDuration + 1) == .completed else {
            XCTFail("SETUP: First-loop rotation timer did not complete; \(raw)", file: file, line: line)
            return nil
        }
        let requestedAt = Date().timeIntervalSince1970
        XCUIDevice.shared.orientation = .landscapeLeft
        let schedule = XCTAttachment(string: "\(raw)\nreceivedEpochMs=\(receivedAt * 1000)\n"
            + "sampleAge=\(age)\nfirstBoundaryEpochMs=\(firstBoundary * 1000)\n"
            + "targetEpochMs=\(target * 1000)\nrotationRequestedEpochMs=\(requestedAt * 1000)")
        schedule.name = "First-loop media clock and native rotation schedule"
        schedule.lifetime = .keepAlways
        add(schedule)
        return firstBoundary
    }

    private func captureDisplay(_ title: String) {
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = title
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    private func expectPopupText(_ text: String, timeout: TimeInterval,
                                 file: StaticString = #filePath, line: UInt = #line) {
        let element = app.webViews.staticTexts[text].firstMatch
        guard element.waitForExistence(timeout: timeout) else {
            XCTFail("Missing rendered popup text: \(text)", file: file, line: line)
            return
        }
        let viewport = app.webViews["contentView"].firstMatch
        let onscreen = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            // Each frame read requests a native snapshot; avoid repeating it within one evaluation.
            let frame = element.frame
            let viewportFrame = viewport.frame
            let windowFrame = self.app.windows.firstMatch.frame
            return frame.minX.isFinite && frame.minY.isFinite && frame.width.isFinite && frame.height.isFinite
                && frame.width > 0 && frame.height > 0 && viewportFrame.contains(frame) && windowFrame.contains(frame)
        }, object: element)
        XCTAssertEqual(XCTWaiter().wait(for: [onscreen], timeout: timeout), .completed,
                       "Popup text must appear inside the native viewport and display: \(text)", file: file, line: line)
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

    private func tapSettingsCell(_ identifier: String) -> Bool {
        let table = app.tables[AccessibilityIdentifiers.Settings.tableViewController]
        mozWaitForElementToExist(table)
        let cell = table.cells[identifier]
        for _ in 0..<10 where !cell.isHittable { table.swipeUp() }
        guard cell.exists && cell.isHittable else {
            XCTFail("Settings cell is not accessible after scrolling: \(identifier)")
            return false
        }
        cell.waitAndTap()
        return true
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
