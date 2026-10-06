import XCTest
final class HarborUITests: XCTestCase {
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
