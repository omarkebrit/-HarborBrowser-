import XCTest
final class HarborUITests: XCTestCase {
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
        XCTAssertTrue(app.buttons["Clear site data"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(clear.exists, "Cancel must keep the current site open")
        clear.tap()
        app.buttons["Clear site data"].tap()
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
