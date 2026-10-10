import XCTest
final class HarborUITests: XCTestCase {
    func testBundledPlaybackCheckPlaysWithoutAWebsite() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset"]
        app.launch()
        XCTAssertTrue(app.buttons["BrowserMenu"].waitForExistence(timeout: 120))
        app.buttons["BrowserMenu"].tap()
        app.buttons["Video playback check"].tap()
        let play = app.webViews.buttons["Play test video"]
        XCTAssertTrue(play.waitForExistence(timeout: 15), "The installed app must contain its offline playback check")
        play.tap()
        XCTAssertTrue(app.webViews.staticTexts["Test video is playing with sound"].waitForExistence(timeout: 15))
        preserveScreenshot(app, name: "Bundled movie playing with sound")
    }

    func testUserGestureWindowOpenLoadsVideoInNewTab() {
        let app = videoApp("popup.html")
        let open = app.webViews.buttons["Open video tab"]
        XCTAssertTrue(open.waitForExistence(timeout: 120))
        open.tap()
        XCTAssertTrue(app.webViews.staticTexts["Network Video Fixture"].waitForExistence(timeout: 15), "A tapped JavaScript video link must open its requested destination")
        app.buttons["Tabs"].tap()
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "OpenTab-"))
        XCTAssertEqual(cards.count, 2, "Only the original page and user-requested video tab should exist")
        XCTAssertTrue(app.buttons["OpenTab-Network Video Fixture"].exists)
    }

    func testUnsolicitedWindowOpenDoesNotCreateVideoTab() {
        let app = videoApp("popup.html")
        XCTAssertTrue(app.webViews.staticTexts["Automatic popup attempted"].waitForExistence(timeout: 120))
        XCTAssertFalse(app.webViews.staticTexts["Unexpected Automatic Popup"].exists)
        app.buttons["Tabs"].tap()
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "OpenTab-"))
        XCTAssertEqual(cards.count, 1, "Automatic JavaScript popups must remain blocked")
    }

    func testVideoWithSoundPlaysAfterRealGestureAndAutoplaySettingChange() {
        let app = videoApp("audio.html")
        XCTAssertTrue(app.webViews.buttons["Play with sound"].waitForExistence(timeout: 120))
        app.buttons["BrowserMenu"].tap()
        app.buttons["Settings"].tap()
        let autoplay = app.switches["Allow media autoplay"]
        for _ in 0..<5 where !autoplay.isHittable { app.swipeUp() }
        XCTAssertTrue(autoplay.waitForExistence(timeout: 5))
        if autoplay.value as? String == "1" { autoplay.tap() }
        app.buttons["Done"].tap()
        let play = app.webViews.buttons["Play with sound"]
        XCTAssertTrue(play.waitForExistence(timeout: 15))
        play.tap()
        XCTAssertTrue(app.webViews.staticTexts["Playing with sound"].waitForExistence(timeout: 15), "A real user gesture must advance the unmuted H.264/AAC movie after changing autoplay settings")
        preserveScreenshot(app, name: "Unmuted movie playing after user gesture")
    }

    func testElementFullscreenVideoSurvivesRotationAndExits() {
        let app = videoApp("fullscreen.html")
        defer { XCUIDevice.shared.orientation = .portrait }
        let enter = app.webViews.buttons["Enter fullscreen"]
        XCTAssertTrue(enter.waitForExistence(timeout: 120))
        enter.tap()
        let playing = app.staticTexts["Fullscreen video playing"]
        XCTAssertTrue(playing.waitForExistence(timeout: 15), "Element fullscreen must show a playing movie after the user's tap")
        XCUIDevice.shared.orientation = .landscapeLeft
        let exit = app.buttons["Exit fullscreen"]
        XCTAssertTrue(exit.waitForExistence(timeout: 10))
        preserveScreenshot(app, name: "Movie in element fullscreen landscape")
        exit.tap()
        XCTAssertTrue(app.webViews.staticTexts["Fullscreen exited"].waitForExistence(timeout: 10), "The movie page must remain attached after a fullscreen rotation and exit")
    }

    private func videoApp(_ page: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset", "--uitest-video-page", "http://127.0.0.1:8765/" + page]
        app.launch()
        return app
    }

    private func preserveScreenshot(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }

    func testClearOneSiteRequiresConfirmationAndPreservesBookmark() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset", "--uitest-fixture"]
        app.launch()
        XCTAssertTrue(app.webViews.staticTexts["Harbor Test Page"].firstMatch.waitForExistence(timeout: 120))
        app.buttons["BrowserMenu"].tap()
        app.buttons["Add bookmark"].tap()
        app.buttons["Site controls"].tap()
        let clear = app.buttons["ClearCurrentSiteData"]
        if !clear.isHittable { app.swipeUp() }
        XCTAssertTrue(clear.waitForExistence(timeout: 5))
        clear.tap()
        let confirmation = app.alerts.firstMatch
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        XCTAssertTrue(confirmation.buttons["Clear site data"].exists)
        confirmation.buttons["Cancel"].tap()
        XCTAssertTrue(clear.exists, "Cancel must keep the current site open")
        clear.tap()
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Clear site data"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["A calmer\nway to browse."].waitForExistence(timeout: 10))
        app.buttons["BrowserMenu"].tap()
        app.buttons["Bookmarks & history"].tap()
        XCTAssertTrue(app.buttons.containing(.staticText, identifier: "Harbor Test Page").firstMatch.waitForExistence(timeout: 5), "Clearing a site's data must keep its saved bookmark")
    }

    func testSelectEntireTabCardAndSwitchBack() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset", "--uitest-tabs"]
        app.launch()
        XCTAssertTrue(app.webViews.staticTexts["Third content"].waitForExistence(timeout: 120))
        app.buttons["Tabs"].tap()
        let first = app.buttons["OpenTab-First tab"]
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        // Tap the icon/padding rather than the text, where the old card had no action.
        first.coordinate(withNormalizedOffset: CGVector(dx: 0.12, dy: 0.12)).tap()
        XCTAssertTrue(app.webViews.staticTexts["First content"].waitForExistence(timeout: 10))
        app.buttons["Tabs"].tap()
        app.buttons["OpenTab-Second tab"].tap()
        XCTAssertTrue(app.webViews.staticTexts["Second content"].waitForExistence(timeout: 10))
        app.buttons["Tabs"].tap()
        app.buttons["Close First tab"].tap()
        XCTAssertFalse(app.buttons["OpenTab-First tab"].exists)
        app.buttons["OpenTab-Third tab"].tap()
        XCTAssertTrue(app.webViews.staticTexts["Third content"].waitForExistence(timeout: 10))
    }
    func testNativeDialogBookmarksAndSettings() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitest-reset", "--uitest-fixture"]
        app.launch()
        XCTAssertTrue(app.textFields["Address"].waitForExistence(timeout: 120))
        let confirm = app.webViews.buttons["Confirm test"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 20)); confirm.tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        app.alerts.buttons["OK"].tap()
        XCTAssertTrue(app.webViews.staticTexts["Confirmed"].waitForExistence(timeout: 5))
        app.buttons["BrowserMenu"].tap(); app.buttons["Add bookmark"].tap()
        app.buttons["BrowserMenu"].tap(); app.buttons["Bookmarks & history"].tap()
        XCTAssertTrue(app.buttons.containing(.staticText, identifier: "Harbor Test Page").firstMatch.waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        app.buttons["BrowserMenu"].tap(); app.buttons["Settings"].tap()
        XCTAssertTrue(app.switches["Restore regular tabs"].waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.lifetime = .keepAlways; add(shot)
        app.buttons["Done"].tap()
        app.buttons["New tab"].tap()
        XCTAssertTrue(app.staticTexts["A calmer\nway to browse."].waitForExistence(timeout: 5))
        let home = XCTAttachment(screenshot: app.screenshot()); home.lifetime = .keepAlways; add(home)
    }
}
