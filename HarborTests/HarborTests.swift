import XCTest
import WebKit
@testable import HarborBrowser

final class HarborTests: XCTestCase {
    func testAddressAndSearch() {
        XCTAssertEqual(BrowserAddress.resolve("example.com/path", engine: .google)?.absoluteString, "https://example.com/path")
        let url = BrowserAddress.resolve("cats & dogs", engine: .duckDuckGo)!
        XCTAssertEqual(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first?.value, "cats & dogs")
        XCTAssertNil(BrowserAddress.resolve("javascript:alert(1)", engine: .google))
        XCTAssertNil(BrowserAddress.resolve("file:///etc/passwd", engine: .google))
        XCTAssertFalse(BrowserAddress.isYouTube("youtube.com.evil.example"))
        XCTAssertTrue(BrowserAddress.isYouTube("m.youtube.com"))
    }
    @MainActor func testPrivateHistoryAndPersistence() {
        let suite = "harbor-test-" + UUID().uuidString
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let library = BrowserLibrary(defaults: defaults)
        let url = URL(string: "https://example.com")!
        library.visit(title: "Private", url: url, isPrivate: true)
        XCTAssertTrue(library.history.isEmpty)
        library.visit(title: "Public", url: url, isPrivate: false)
        library.addBookmark(title: "Example", url: url)
        library.addBookmark(title: "Duplicate", url: url)
        let restored = BrowserLibrary(defaults: defaults)
        XCTAssertEqual(restored.history.count, 1)
        XCTAssertEqual(restored.bookmarks.count, 1)
        library.preferences.restoreTabs = false
        library.saveSession(BrowserSession(urls: [url.absoluteString], selectedIndex: 0))
        XCTAssertNil(library.session)
    }
    @MainActor func testVideoAndProtectionIsolation() async throws {
        let tab = BrowserTab(isPrivate: true, store: .nonPersistent(), rules: [], preferences: BrowserPreferences(), downloads: DownloadManager())
        XCTAssertTrue(tab.webView.configuration.allowsInlineMediaPlayback)
        XCTAssertTrue(tab.webView.configuration.mediaTypesRequiringUserActionForPlayback.isEmpty)
        tab.applyProtection(URL(string: "https://m.youtube.com/watch?v=test"))
        XCTAssertEqual(tab.protection, "Video compatibility")
        tab.applyProtection(URL(string: "https://example.com"))
        XCTAssertEqual(tab.protection, "Protected")
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let controller = UIViewController(); window.rootViewController = controller
        controller.view.addSubview(tab.webView); tab.webView.frame = controller.view.bounds
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let resource = Bundle(for: Self.self).url(forResource: "video", withExtension: "b64")!
        let data = try String(contentsOf: resource)
        tab.webView.loadHTMLString("<html><body><video id='v' playsinline muted controls src='data:video/mp4;base64,\(data)'></video></body></html>", baseURL: URL(string: "https://fixture.example"))
        var documentReady = false
        for _ in 0..<100 {
            if (try? await tab.webView.evaluateJavaScript("!!document.getElementById('v')")) as? Bool == true { documentReady = true; break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertTrue(documentReady, "Video element must exist")
        _ = try await tab.webView.evaluateJavaScript("document.getElementById('v').play(); true")
        var time = 0.0
        for _ in 0..<100 {
            time = (try? await tab.webView.evaluateJavaScript("document.getElementById('v').currentTime")) as? Double ?? 0
            if time > 0.1 { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertGreaterThan(time, 0.1, "Media must actually advance after play is requested")
        let mediaError = try await tab.webView.evaluateJavaScript("document.getElementById('v').error?.code || 0") as? Int
        XCTAssertEqual(mediaError, 0)
    }
}
