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
    func testAddressRejectsCredentialsInsteadOfLoadingOrSearching() {
        let inputs = [
            "https://user:password@example.com/private",
            "http://user@example.com/private",
            "https://%75ser:%70assword@example.com/private",
            "https://@example.com/private",
            "user:password@example.com/private",
            "user@example.com/private"
        ]
        for input in inputs {
            for requireHTTPS in [false, true] {
                XCTAssertNil(BrowserAddress.resolve(input, engine: .google, requireHTTPS: requireHTTPS), input)
            }
        }
    }
    func testAddressRejectsUnsupportedSchemesRegardlessOfCase() throws {
        let inputs = [
            "JaVaScRiPt:alert(1)", "DaTa:text/plain,hello",
            "FiLe:///etc/passwd", "FTP://example.com/readme",
            "BLOB:https://example.com/identifier"
        ]
        for input in inputs {
            XCTAssertNil(BrowserAddress.resolve(input, engine: .duckDuckGo), input)
            let url = try XCTUnwrap(URL(string: input))
            XCTAssertNil(BrowserAddress.validated(url), input)
        }
    }
    func testValidatedAddressRejectsUserInfo() throws {
        for input in ["https://user:password@example.com/", "https://user@example.com/", "https://@example.com/"] {
            let url = try XCTUnwrap(URL(string: input))
            XCTAssertNil(BrowserAddress.validated(url), input)
            XCTAssertNil(BrowserAddress.validated(url, requireHTTPS: true), input)
        }
    }
    func testHTTPSUpgradePreservesEncodedPathQueryAndFragment() throws {
        let input = "http://example.com/a%2Fb?q=one%20two%26three&redirect=http%3A%2F%2Felsewhere.test%2F%3Fx%3D1#part%202"
        let original = try XCTUnwrap(URLComponents(string: input))
        let resolved = try XCTUnwrap(BrowserAddress.resolve(input, engine: .google, requireHTTPS: true))
        let upgraded = try XCTUnwrap(URLComponents(url: resolved, resolvingAgainstBaseURL: false))
        XCTAssertEqual(upgraded.scheme, "https")
        XCTAssertEqual(upgraded.host, original.host)
        XCTAssertEqual(upgraded.percentEncodedPath, original.percentEncodedPath)
        XCTAssertEqual(upgraded.percentEncodedQuery, original.percentEncodedQuery)
        XCTAssertEqual(upgraded.percentEncodedFragment, original.percentEncodedFragment)
        let url = try XCTUnwrap(original.url)
        XCTAssertEqual(BrowserAddress.validated(url, requireHTTPS: true), resolved)
    }
    func testHTTPSUpgradeRemovesOnlyHTTPDefaultPort() throws {
        let defaultPort = try XCTUnwrap(BrowserAddress.resolve("http://example.com:80/path?x=1#part", engine: .google, requireHTTPS: true))
        XCTAssertEqual(defaultPort.scheme, "https")
        XCTAssertNil(defaultPort.port)
        XCTAssertEqual(defaultPort.absoluteString, "https://example.com/path?x=1#part")
        let customPort = try XCTUnwrap(BrowserAddress.resolve("http://example.com:8080/path?x=1#part", engine: .google, requireHTTPS: true))
        XCTAssertEqual(customPort.scheme, "https")
        XCTAssertEqual(customPort.port, 8080)
        XCTAssertEqual(customPort.absoluteString, "https://example.com:8080/path?x=1#part")
        let alreadyHTTPS = try XCTUnwrap(URL(string: "https://example.com:8443/path"))
        XCTAssertEqual(BrowserAddress.validated(alreadyHTTPS, requireHTTPS: true), alreadyHTTPS)
    }
    func testHTTPSOptInLeavesLoopbackHTTPUsableByDefault() throws {
        for input in ["http://127.0.0.1:8765/video.mp4?start=1#frame", "http://localhost:8765/video.html", "http://[::1]:8765/video.html"] {
            let original = try XCTUnwrap(URL(string: input))
            XCTAssertEqual(BrowserAddress.resolve(input, engine: .google), original)
            XCTAssertEqual(BrowserAddress.resolve(input, engine: .google, requireHTTPS: false), original)
            XCTAssertEqual(BrowserAddress.validated(original), original)
            XCTAssertEqual(BrowserAddress.validated(original, requireHTTPS: false), original)
        }
    }
    func testHTTPSNavigationUpgradePreservesPOSTRequest() throws {
        let input = try XCTUnwrap(URL(string: "http://example.com:8080/submit?source=popup%20form#result"))
        var request = URLRequest(url: input, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 37)
        request.httpMethod = "POST"
        request.httpBody = Data("token=a%2Bb%26c&query=two+words".utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("popup-form-request", forHTTPHeaderField: "X-Request-ID")
        request.httpShouldHandleCookies = false
        let upgraded = try XCTUnwrap(BrowserAddress.requestForNavigation(request, requireHTTPS: true))
        XCTAssertEqual(upgraded.url?.absoluteString, "https://example.com:8080/submit?source=popup%20form#result")
        XCTAssertEqual(upgraded.httpMethod, "POST")
        XCTAssertEqual(upgraded.httpBody, request.httpBody)
        XCTAssertEqual(upgraded.allHTTPHeaderFields, request.allHTTPHeaderFields)
        XCTAssertEqual(upgraded.cachePolicy, request.cachePolicy)
        XCTAssertEqual(upgraded.timeoutInterval, 37)
        XCTAssertFalse(upgraded.httpShouldHandleCookies)
        XCTAssertEqual(BrowserAddress.requestForNavigation(request), request)
        request.url = URL(string: "http://user:password@example.com/submit")
        XCTAssertNil(BrowserAddress.requestForNavigation(request, requireHTTPS: true))
    }
    func testSpecialSearchCharactersRoundTripForEveryEngine() throws {
        let queries = ["C++ & café? #100% / =🙂", "cats & dogs", "a+b=c&redirect=https://example.com/?q=two words#part"]
        for engine in SearchEngine.allCases {
            for query in queries {
                let resolved = try XCTUnwrap(BrowserAddress.resolve(query, engine: engine))
                let parts = try XCTUnwrap(URLComponents(url: resolved, resolvingAgainstBaseURL: false))
                XCTAssertEqual(parts.scheme, "https", engine.rawValue)
                XCTAssertEqual(parts.queryItems?.count, 1, engine.rawValue)
                XCTAssertEqual(parts.queryItems?.first?.name, "q", engine.rawValue)
                XCTAssertEqual(parts.queryItems?.first?.value, query, engine.rawValue)
            }
        }
    }
    func testSiteHostNormalization() {
        XCTAssertEqual(BrowserSiteData.normalizedHost(".WWW.Example.COM."), "www.example.com")
        XCTAssertEqual(BrowserSiteData.normalizedHost("example.com..."), "example.com")
        XCTAssertEqual(BrowserSiteData.normalizedHost("[2001:DB8::1]"), "2001:db8::1")
        XCTAssertEqual(BrowserSiteData.normalizedHost("[::1]"), "::1")
        XCTAssertEqual(BrowserSiteData.normalizedHost("127.0.0.1"), "127.0.0.1")
        XCTAssertEqual(BrowserSiteData.normalizedHost("..."), "")
    }
    func testSiteMatchingTreatsUnicodeAndPunycodeAsTheSameHost() {
        XCTAssertEqual(BrowserSiteData.normalizedHost("BÜCHER.DE."), BrowserSiteData.normalizedHost("xn--bcher-kva.de"))
        XCTAssertTrue(BrowserSiteData.matches("bücher.de", host: "xn--bcher-kva.de"))
        XCTAssertTrue(BrowserSiteData.matches("xn--bcher-kva.de", host: "bücher.de"))
        XCTAssertTrue(BrowserSiteData.matches("www.bücher.de", host: "xn--bcher-kva.de"))
        XCTAssertFalse(BrowserSiteData.matches("bücher.de.evil.test", host: "xn--bcher-kva.de", includeParentDomains: true))
    }
    func testSiteMatchingUsesWholeDomainLabels() {
        XCTAssertTrue(BrowserSiteData.matches("example.com", host: "example.com"))
        XCTAssertTrue(BrowserSiteData.matches("www.example.com", host: "example.com"))
        XCTAssertTrue(BrowserSiteData.matches("a.b.example.com", host: "example.com"))
        XCTAssertTrue(BrowserSiteData.matches(".WWW.Example.COM.", host: "EXAMPLE.COM."))
        for domain in ["notexample.com", "example.com.evil.test", "www.example.com.evil.test"] {
            XCTAssertFalse(BrowserSiteData.matches(domain, host: "example.com"), domain)
            XCTAssertFalse(BrowserSiteData.matches(domain, host: "example.com", includeParentDomains: true), domain)
        }
        XCTAssertFalse(BrowserSiteData.matches("example.com", host: "notexample.com", includeParentDomains: true))
        XCTAssertFalse(BrowserSiteData.matches("", host: "example.com"))
        XCTAssertFalse(BrowserSiteData.matches("example.com", host: ""))
    }
    func testParentSiteMatchingRequiresOptInAndRejectsSingleLabels() {
        XCTAssertFalse(BrowserSiteData.matches("example.com", host: "www.example.com"))
        XCTAssertTrue(BrowserSiteData.matches("example.com", host: "www.example.com", includeParentDomains: true))
        XCTAssertTrue(BrowserSiteData.matches(".Example.COM.", host: "a.b.example.com", includeParentDomains: true))
        XCTAssertFalse(BrowserSiteData.matches("com", host: "example.com", includeParentDomains: true))
        XCTAssertFalse(BrowserSiteData.matches("example.com", host: "com", includeParentDomains: true))
        XCTAssertFalse(BrowserSiteData.matches("localhost", host: "a.localhost", includeParentDomains: true))
    }
    func testIPAddressMatchingIsExactAfterNormalization() {
        XCTAssertTrue(BrowserSiteData.matches("127.0.0.1", host: "127.0.0.1"))
        XCTAssertTrue(BrowserSiteData.matches("[::1]", host: "::1"))
        XCTAssertTrue(BrowserSiteData.matches("2001:db8::1", host: "[2001:DB8::1]"))
        for includeParents in [false, true] {
            XCTAssertFalse(BrowserSiteData.matches("127.0.0.1", host: "0.0.1", includeParentDomains: includeParents))
            XCTAssertFalse(BrowserSiteData.matches("0.0.1", host: "127.0.0.1", includeParentDomains: includeParents))
            XCTAssertFalse(BrowserSiteData.matches("127.0.0.2", host: "127.0.0.1", includeParentDomains: includeParents))
            XCTAssertFalse(BrowserSiteData.matches("::1", host: "2001:db8::1", includeParentDomains: includeParents))
        }
    }
    func testSiteMatchingSeparatesPublicSuffixesAndSharedHostingTenants() {
        XCTAssertFalse(BrowserSiteData.matches("github.io", host: "foo.github.io", includeParentDomains: true))
        XCTAssertFalse(BrowserSiteData.matches("foo.github.io", host: "github.io", includeParentDomains: true))
        XCTAssertFalse(BrowserSiteData.matches("foo.github.io", host: "bar.github.io", includeParentDomains: true))
        XCTAssertFalse(BrowserSiteData.matches("co.uk", host: "example.co.uk", includeParentDomains: true))
        XCTAssertFalse(BrowserSiteData.matches("example.co.uk", host: "co.uk", includeParentDomains: true))
        XCTAssertTrue(BrowserSiteData.matches("sub.example.co.uk", host: "example.co.uk"))
        XCTAssertTrue(BrowserSiteData.matches("example.co.uk", host: "sub.example.co.uk", includeParentDomains: true))
        XCTAssertFalse(BrowserSiteData.matches("evil-example.co.uk", host: "example.co.uk", includeParentDomains: true))
    }
    func testPublicSuffixRulesHonorWildcardsAndExceptions() {
        let rules = PublicSuffixRules(contents: """
        com
        uk
        co.uk
        io
        github.io
        jp
        *.kawasaki.jp
        !city.kawasaki.jp
        """)
        XCTAssertNil(rules.registrableDomain(".COM"))
        XCTAssertNil(rules.registrableDomain("co.uk"))
        XCTAssertNil(rules.registrableDomain("github.io"))
        XCTAssertEqual(rules.registrableDomain(".WWW.Example.COM."), "example.com")
        XCTAssertEqual(rules.registrableDomain("foo.github.io"), "foo.github.io")
        XCTAssertNil(rules.registrableDomain("foo.kawasaki.jp"))
        XCTAssertEqual(rules.registrableDomain("bar.foo.kawasaki.jp"), "bar.foo.kawasaki.jp")
        XCTAssertEqual(rules.registrableDomain("city.kawasaki.jp"), "city.kawasaki.jp")
        XCTAssertEqual(rules.registrableDomain("www.city.kawasaki.jp"), "city.kawasaki.jp")
    }
    func testPreferencesUpgradeKeepsExistingSettings() throws {
        let old = Data("{\"searchEngine\":\"Google\",\"theme\":\"Dark\",\"blockAds\":false,\"youtubeCompatibility\":true}".utf8)
        let migrated = try JSONDecoder().decode(BrowserPreferences.self, from: old)
        XCTAssertEqual(migrated.searchEngine, .google)
        XCTAssertEqual(migrated.theme, .dark)
        XCTAssertFalse(migrated.blockAds)
        XCTAssertFalse(migrated.requireHTTPS)
        XCTAssertTrue(migrated.videoCompatibility(for: "www.erome.com"))
        XCTAssertFalse(migrated.videoCompatibility(for: "erome.com.example.org"))
    }
    func testHTTPSPreferenceRoundTripsWithoutChangingOtherSettings() throws {
        var preferences = BrowserPreferences()
        XCTAssertFalse(preferences.requireHTTPS)
        preferences.requireHTTPS = true
        preferences.blockAds = false
        preferences.searchEngine = .brave
        let restored = try JSONDecoder().decode(BrowserPreferences.self, from: JSONEncoder().encode(preferences))
        XCTAssertTrue(restored.requireHTTPS)
        XCTAssertFalse(restored.blockAds)
        XCTAssertEqual(restored.searchEngine, .brave)
        XCTAssertEqual(restored, preferences)
    }
    @MainActor func testNetworkVideoPlayback() async throws {
        let tab = BrowserTab(isPrivate: true, store: .nonPersistent(), rules: [], preferences: BrowserPreferences(), downloads: DownloadManager())
        let window = mount(tab)
        defer { window.isHidden = true }
        tab.load(URL(string: "http://127.0.0.1:8765/video.html")!)
        try await playAndCheck(tab)
        XCTAssertEqual(tab.title, "Network Video Fixture")
        XCTAssertTrue(tab.downloads.items.allSatisfy { $0.state != "Downloading" }, "Playing media must not create a download")
    }
    @MainActor func testDefaultProtectionAllowsNetworkVideoPlaybackAndSeeking() async throws {
        let tab = try await protectedTab(isPrivate: false)
        let window = mount(tab)
        defer { window.isHidden = true }
        tab.load(URL(string: "http://127.0.0.1:8765/video.html")!)
        try await playAndCheck(tab)
        XCTAssertEqual(tab.protection, "Protected")
        _ = try await tab.webView.evaluateJavaScript("document.getElementById('v').currentTime = 4; true")
        var seekCompleted = false
        for _ in 0..<100 {
            if (try? await tab.webView.evaluateJavaScript("(() => { const v = document.getElementById('v'); return !v.seeking && v.currentTime > 4.1 && !v.paused; })()")) as? Bool == true {
                seekCompleted = true; break
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        let seekDiagnostic = await playbackDiagnostic(tab)
        XCTAssertTrue(seekCompleted, "Protected video must play after seeking: \(seekDiagnostic)")
        XCTAssertTrue(tab.downloads.items.allSatisfy { $0.state != "Downloading" })
    }
    @MainActor func testProtectedIframeVideoPlayback() async throws {
        let tab = try await protectedTab()
        let window = mount(tab)
        defer { window.isHidden = true }
        tab.load(URL(string: "http://127.0.0.1:8765/iframe.html")!)
        try await playAndCheck(tab, selector: "document.getElementById('player')?.contentDocument?.getElementById('v')")
        XCTAssertTrue(tab.downloads.items.allSatisfy { $0.state != "Downloading" }, "Iframe media must stay in the player")
    }
    @MainActor func testProtectedBlobVideoPlayback() async throws {
        let tab = try await protectedTab()
        let window = mount(tab)
        defer { window.isHidden = true }
        tab.load(URL(string: "http://127.0.0.1:8765/blob.html")!)
        try await playAndCheck(tab)
        let source = try await tab.webView.evaluateJavaScript("document.getElementById('v').currentSrc") as? String
        XCTAssertTrue(source?.hasPrefix("blob:") == true)
    }
    @MainActor func testDirectMP4NavigationPlaysInsteadOfDownloading() async throws {
        let tab = try await protectedTab()
        let window = mount(tab)
        defer { window.isHidden = true }
        tab.load(URL(string: "http://127.0.0.1:8765/video.mp4")!)
        try await playAndCheck(tab, selector: "document.querySelector('video')")
        XCTAssertTrue(tab.downloads.items.allSatisfy { $0.state != "Downloading" }, "Direct video navigation must not be hijacked as a download")
        XCTAssertEqual(tab.webView.url?.path, "/video.mp4")
    }
    @MainActor func testProtectedHLSVideoPlayback() async throws {
        let tab = try await protectedTab()
        let window = mount(tab)
        defer { window.isHidden = true }
        tab.load(URL(string: "http://127.0.0.1:8765/hls.html")!)
        try await playAndCheck(tab)
        let source = try await tab.webView.evaluateJavaScript("document.getElementById('v').currentSrc") as? String
        XCTAssertTrue(source?.hasSuffix("playlist.m3u8") == true)
        XCTAssertTrue(tab.downloads.items.allSatisfy { $0.state != "Downloading" }, "HLS playlists and segments must remain WebKit media")
    }
    @MainActor private func protectedTab(isPrivate: Bool = true) async throws -> BrowserTab {
        let blocker = BlockingStore()
        let lists = try await blocker.load()
        XCTAssertGreaterThan(blocker.ruleCount, 1000, "Playback coverage must include the generated production filter pack")
        return BrowserTab(isPrivate: isPrivate, store: .nonPersistent(), rules: lists, preferences: BrowserPreferences(), downloads: DownloadManager())
    }
    @MainActor func testEromeCompatibilityAllowsMediaDespiteBlockingRule() async throws {
        let json = Data("[{\"trigger\":{\"url-filter\":\".*\",\"resource-type\":[\"media\"]},\"action\":{\"type\":\"block\"}}]".utf8)
        let rule = try await BlockingStore().compile(json)
        let tab = BrowserTab(isPrivate: true, store: .nonPersistent(), rules: [rule], preferences: BrowserPreferences(), downloads: DownloadManager())
        let window = mount(tab)
        defer { window.isHidden = true }
        // HTTP base avoids mixed-content restrictions for the loopback HTTP fixture.
        let site = URL(string: "http://www.erome.com")!
        tab.applyProtection(site)
        XCTAssertEqual(tab.protection, "Video compatibility")
        tab.webView.loadHTMLString("<html><body><video id='v' playsinline muted controls src='http://127.0.0.1:8765/video.mp4'></video></body></html>", baseURL: site)
        try await playAndCheck(tab)
    }
    @MainActor func testLiveYouTubePageLoads() async throws {
        let tab = BrowserTab(isPrivate: true, store: .nonPersistent(), rules: [], preferences: BrowserPreferences(), downloads: DownloadManager())
        let window = mount(tab)
        defer { window.isHidden = true }
        tab.load(URL(string: "https://www.youtube.com")!)
        var loaded = false
        for _ in 0..<450 {
            let state = (try? await tab.webView.evaluateJavaScript("JSON.stringify({title:document.title,chars:document.body?.innerText.length||0,player:!!document.querySelector('ytm-app,ytd-app'),url:location.href})")) as? String
            if let state, let data = state.data(using: .utf8), let info = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let chars = info["chars"] as? Int, chars > 20, (info["title"] as? String)?.localizedCaseInsensitiveContains("youtube") == true {
                print("YOUTUBE_PAGE_DIAGNOSTIC " + state); loaded = true; break
            }
            if tab.error != nil { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertTrue(loaded, "Live YouTube did not render: \(tab.error ?? tab.title)")
    }
    @MainActor private func mount(_ tab: BrowserTab) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let controller = UIViewController(); window.rootViewController = controller
        controller.view.addSubview(tab.webView); tab.webView.frame = controller.view.bounds
        window.makeKeyAndVisible(); return window
    }
    @MainActor private func playAndCheck(_ tab: BrowserTab, selector: String = "document.getElementById('v')") async throws {
        var documentReady = false
        for _ in 0..<150 {
            if (try? await tab.webView.evaluateJavaScript("(() => { const v = \(selector); return !!v && !!(v.currentSrc || v.src); })()")) as? Bool == true { documentReady = true; break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        let initialDiagnostic = await playbackDiagnostic(tab, selector: selector)
        XCTAssertTrue(documentReady, "Video DOM and source must render: \(initialDiagnostic)")
        guard documentReady else { return }
        _ = try await tab.webView.evaluateJavaScript("(() => { const v = \(selector); v.play().catch(error => { window.playbackError = error.name + ': ' + error.message; }); return true; })()")
        var time = 0.0
        for _ in 0..<150 {
            time = (try? await tab.webView.evaluateJavaScript("(\(selector)).currentTime")) as? Double ?? 0
            if time > 0.25 { break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        let diagnostic = await playbackDiagnostic(tab, selector: selector)
        print("VIDEO_PLAYBACK_DIAGNOSTIC " + diagnostic)
        XCTAssertGreaterThan(time, 0.25, "Video must advance after a play request: \(diagnostic)")
        let mediaError = try await tab.webView.evaluateJavaScript("(\(selector)).error?.code || 0") as? Int
        XCTAssertEqual(mediaError, 0, diagnostic)
        let decodedWidth = try await tab.webView.evaluateJavaScript("(\(selector)).videoWidth") as? Int ?? 0
        XCTAssertGreaterThan(decodedWidth, 0, "The player must decode actual video frames: \(diagnostic)")
    }
    @MainActor private func playbackDiagnostic(_ tab: BrowserTab, selector: String = "document.getElementById('v')") async -> String {
        let script = """
        (() => {
            const v = \(selector);
            return JSON.stringify({url: location.href, ua: navigator.userAgent,
                source: v?.currentSrc || v?.src, time: v?.currentTime,
                duration: v?.duration, paused: v?.paused, muted: v?.muted,
                width: v?.videoWidth, ready: v?.readyState, network: v?.networkState,
                error: v?.error?.code, message: v?.error?.message,
                playError: window.playbackError, fixtureError: window.fixtureError});
        })()
        """
        let state = (try? await tab.webView.evaluateJavaScript(script)) as? String ?? "No JavaScript media state"
        return "\(state); navigation: \(tab.error ?? "none"); protection: \(tab.protection)"
    }
    @MainActor func testSettingsKeepSubmittedVideoPageWithoutRepeatingPOST() async throws {
        let suite = "harbor-post-retention-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = BrowserModel(defaults: defaults)
        model.library.preferences.restoreTabs = false
        await model.prepare()
        let tab = try XCTUnwrap(model.current, "The browser must prepare a real tab")
        let window = mount(tab)
        defer { window.isHidden = true }
        let token = UUID().uuidString
        let body = "submission=" + token
        var request = URLRequest(url: URL(string: "http://127.0.0.1:8765/submitted.html")!)
        request.httpMethod = "POST"
        request.httpBody = Data(body.utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        tab.loadRequest(request)
        var submitted = false
        for _ in 0..<150 {
            let echoed = (try? await tab.webView.evaluateJavaScript("document.getElementById('submission')?.textContent")) as? String
            if echoed == body { submitted = true; break }
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        XCTAssertTrue(submitted, "The real HTTP POST body must reach its video page")
        guard submitted else { return }
        _ = try await tab.webView.evaluateJavaScript("window.postRetentionMarker = '\(token)'; true")

        // Updating filters normally reloads GET pages. A POST result must keep
        // its live document, rather than repeating the submission or using GET.
        model.library.preferences.blockAds.toggle()
        model.applySettings()
        for _ in 0..<10 {
            try await Task.sleep(nanoseconds: 100_000_000)
            let marker = (try? await tab.webView.evaluateJavaScript("window.postRetentionMarker")) as? String
            XCTAssertEqual(marker, token, "Changing filters must retain a submitted page's JavaScript state")
        }
        XCTAssertTrue(model.current === tab)

        // Autoplay is immutable in a WKWebView configuration. Refusing to
        // recreate this POST document must also preserve its original page.
        model.library.preferences.allowAutoplay.toggle()
        model.applySettings()
        XCTAssertTrue(model.current === tab, "An immutable playback setting must not replace a submitted page")
        for _ in 0..<10 {
            try await Task.sleep(nanoseconds: 100_000_000)
            let marker = (try? await tab.webView.evaluateJavaScript("window.postRetentionMarker")) as? String
            XCTAssertEqual(marker, token, "Changing autoplay must retain a submitted page's JavaScript state")
        }
        XCTAssertTrue(tab.error?.contains("submitted page was kept") == true)
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
    @MainActor func testRetiringSiteDocumentStopsOldScripts() async throws {
        let tab = BrowserTab(isPrivate: true, store: .nonPersistent(), rules: [], preferences: BrowserPreferences(), downloads: DownloadManager())
        let window = mount(tab)
        defer { window.isHidden = true }
        let html = """
        <html><head><title>Retirement fixture</title></head><body><p id="original">Original page</p>
        <script>
        window.retirementMarker = 'active';
        window.retirementTicks = 0;
        window.retirementTimer = setInterval(function () {
            window.retirementTicks += 1;
            document.title = 'Retirement fixture';
        }, 20);
        </script></body></html>
        """
        try await loadLocalDocument(html, title: "Retirement fixture", in: tab, baseURL: URL(string: "https://retirement.example.test/")!)
        let activeScript = try await tab.webView.evaluateJavaScript("window.retirementMarker === 'active' && typeof window.retirementTimer === 'number'") as? Bool
        XCTAssertEqual(activeScript, true)
        let retired = await tab.retireForSiteDataRemoval()
        XCTAssertTrue(retired, "Retirement must commit a new document before removing site data")
        guard retired else { return }
        try await Task.sleep(nanoseconds: 150_000_000)
        let oldDocumentGone = try await tab.webView.evaluateJavaScript("document.title === '' && !document.getElementById('original') && typeof window.retirementMarker === 'undefined' && typeof window.retirementTimer === 'undefined' && typeof window.retirementTicks === 'undefined'") as? Bool
        XCTAssertEqual(oldDocumentGone, true, "A retained closed tab must no longer contain its original scripts or document")
    }
    @MainActor func testClearingCurrentSitePreservesUnrelatedTabsCookiesAndSavedPages() async throws {
        let suite = "harbor-site-data-test-" + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = BrowserModel(defaults: defaults)
        let store = WKWebsiteDataStore.nonPersistent()
        let target = BrowserTab(isPrivate: true, store: store, rules: [], preferences: model.library.preferences, downloads: model.downloads)
        let related = BrowserTab(isPrivate: true, store: store, rules: [], preferences: model.library.preferences, downloads: model.downloads)
        let unrelated = BrowserTab(isPrivate: true, store: store, rules: [], preferences: model.library.preferences, downloads: model.downloads)
        let windows = [mount(target), mount(related), mount(unrelated)]
        defer { windows.forEach { $0.isHidden = true } }
        let targetURL = try XCTUnwrap(URL(string: "https://www.example.test/"))
        let parentURL = try XCTUnwrap(URL(string: "https://example.test/"))
        let unrelatedURL = try XCTUnwrap(URL(string: "https://other.test/"))
        try await loadLocalDocument("<html><head><title>Target site</title></head><body>Target</body></html>", title: "Target site", in: target, baseURL: targetURL)
        try await loadLocalDocument("<html><head><title>Related site</title></head><body>Related</body></html>", title: "Related site", in: related, baseURL: parentURL)
        try await loadLocalDocument("<html><head><title>Other site</title></head><body>Other</body></html>", title: "Other site", in: unrelated, baseURL: unrelatedURL)
        XCTAssertEqual(try XCTUnwrap(target.webView.url?.host), "www.example.test")
        XCTAssertEqual(try XCTUnwrap(related.webView.url?.host), "example.test")
        XCTAssertEqual(try XCTUnwrap(unrelated.webView.url?.host), "other.test")
        let parentCookie = try XCTUnwrap(HTTPCookie(properties: [.domain: ".example.test", .path: "/", .name: "parent-cookie", .value: "remove", .secure: "TRUE"]))
        let targetCookie = try XCTUnwrap(HTTPCookie(properties: [.domain: "www.example.test", .path: "/", .name: "target-cookie", .value: "remove", .secure: "TRUE"]))
        let otherCookie = try XCTUnwrap(HTTPCookie(properties: [.domain: "other.test", .path: "/", .name: "other-cookie", .value: "preserve", .secure: "TRUE"]))
        for cookie in [parentCookie, targetCookie, otherCookie] { await storeCookie(cookie, in: store) }
        let originalCookies = await allCookies(in: store)
        XCTAssertEqual(Set(originalCookies.map(\.name)), Set(["parent-cookie", "target-cookie", "other-cookie"]))
        model.library.addBookmark(title: "Saved target", url: targetURL)
        model.library.addBookmark(title: "Saved unrelated", url: unrelatedURL)
        model.library.visit(title: "Previous target visit", url: targetURL, isPrivate: false)
        model.library.visit(title: "Previous unrelated visit", url: unrelatedURL, isPrivate: false)
        let savedBookmarks = model.library.bookmarks
        let savedHistory = model.library.history
        model.tabs = [target, related, unrelated]; model.selected = target.id; model.ready = true
        await model.clearCurrentSiteData()
        XCTAssertFalse(model.busy)
        XCTAssertEqual(model.tabs.map(\.id), [unrelated.id], "Only tabs sharing the cleared site's storage scope should close")
        XCTAssertEqual(model.current?.id, unrelated.id)
        XCTAssertEqual(unrelated.webView.url, unrelatedURL)
        let remainingCookies = await allCookies(in: store)
        XCTAssertEqual(remainingCookies.count, 1)
        XCTAssertEqual(remainingCookies.first?.name, "other-cookie")
        XCTAssertEqual(remainingCookies.first?.value, "preserve")
        XCTAssertEqual(model.library.bookmarks, savedBookmarks)
        XCTAssertEqual(model.library.history, savedHistory)
        let persistedLibrary = BrowserLibrary(defaults: defaults)
        XCTAssertEqual(persistedLibrary.bookmarks, savedBookmarks)
        XCTAssertEqual(persistedLibrary.history, savedHistory)
        let unrelatedTitle = try await unrelated.webView.evaluateJavaScript("document.title") as? String
        XCTAssertEqual(unrelatedTitle, "Other site", "The unrelated document should remain loaded")
    }
    @MainActor private func loadLocalDocument(_ html: String, title: String, in tab: BrowserTab, baseURL: URL) async throws {
        tab.webView.loadHTMLString(html, baseURL: baseURL)
        for _ in 0..<150 {
            if (try? await tab.webView.evaluateJavaScript("document.title")) as? String == title { return }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        throw NSError(domain: "HarborTests.LocalDocument", code: 1, userInfo: [NSLocalizedDescriptionKey: "The local \(title) document did not become ready."])
    }
    @MainActor private func storeCookie(_ cookie: HTTPCookie, in store: WKWebsiteDataStore) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            store.httpCookieStore.setCookie(cookie) { continuation.resume() }
        }
    }
    @MainActor private func allCookies(in store: WKWebsiteDataStore) async -> [HTTPCookie] {
        await withCheckedContinuation { (continuation: CheckedContinuation<[HTTPCookie], Never>) in
            store.httpCookieStore.getAllCookies { continuation.resume(returning: $0) }
        }
    }
    @MainActor func testVideoAndProtectionIsolation() async throws {
        let tab = BrowserTab(isPrivate: true, store: .nonPersistent(), rules: [], preferences: BrowserPreferences(), downloads: DownloadManager())
        XCTAssertTrue(tab.webView.configuration.allowsInlineMediaPlayback)
        XCTAssertTrue(tab.webView.configuration.mediaTypesRequiringUserActionForPlayback.isEmpty)
        tab.applyProtection(URL(string: "https://m.youtube.com/watch?v=test"))
        XCTAssertEqual(tab.protection, "Video compatibility")
        tab.applyProtection(URL(string: "https://example.com"))
        XCTAssertEqual(tab.protection, "Protection unavailable")
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
