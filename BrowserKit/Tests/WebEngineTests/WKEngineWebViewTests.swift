// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine
import WebKit

@MainActor
private final class TemporaryLoadObserverDiagnostics: NSObject, WKNavigationDelegate {
    let variant: String
    private var observations: [NSKeyValueObservation] = []
    private(set) var events: [String] = []

    init(variant: String) {
        self.variant = variant
    }

    static var application: UIApplication? {
        UIApplication.perform(NSSelectorFromString("sharedApplication"))?.takeUnretainedValue() as? UIApplication
    }

    func record(_ event: String, webView: WKWebView) {
        let application = Self.application
        let window = webView.window
        let state = application.map { String($0.applicationState.rawValue) } ?? "nil"
        let message = "AsterWKLoadDiagnostic variant=\(variant) epoch=\(Date().timeIntervalSince1970) "
            + "uptime=\(ProcessInfo.processInfo.systemUptime) mainThread=\(Thread.isMainThread) event=\(event) "
            + "loading=\(webView.isLoading) progress=\(webView.estimatedProgress) "
            + "title=\(String(describing: webView.title)) url=\(String(describing: webView.url)) "
            + "frame=\(webView.frame) bounds=\(webView.bounds) contentSize=\(webView.scrollView.contentSize) "
            + "applicationState=\(state) window=\(String(describing: window.map(ObjectIdentifier.init))) "
            + "windowHidden=\(String(describing: window?.isHidden)) "
            + "keyWindow=\(String(describing: window?.isKeyWindow)) "
            + "sceneState=\(String(describing: window?.windowScene?.activationState.rawValue))"
        events.append(message)
        print(message)
    }

    func observe(_ webView: WKWebView) {
        observe(\WKWebView.isLoading, on: webView, name: "isLoading", webView: webView)
        observe(\WKWebView.title, on: webView, name: "title", webView: webView)
        observe(\WKWebView.url, on: webView, name: "url", webView: webView)
        observe(\WKWebView.estimatedProgress, on: webView, name: "estimatedProgress", webView: webView)
        observe(\WKWebView.canGoBack, on: webView, name: "canGoBack", webView: webView)
        observe(\WKWebView.canGoForward, on: webView, name: "canGoForward", webView: webView)
        observe(\UIScrollView.contentSize, on: webView.scrollView, name: "contentSize", webView: webView)
        observe(\WKWebView.hasOnlySecureContent, on: webView, name: "hasOnlySecureContent", webView: webView)
    }

    private func observe<Object: NSObject, Value>(
        _ keyPath: KeyPath<Object, Value>,
        on object: Object,
        name: String,
        webView: WKWebView
    ) {
        let observation = object.observe(keyPath, options: [.initial, .old, .new]) { [weak self, weak webView] _, change in
            let event = "KVO \(name) old=\(String(describing: change.oldValue)) "
                + "new=\(String(describing: change.newValue)) "
                + "callbackEpoch=\(Date().timeIntervalSince1970) callbackMainThread=\(Thread.isMainThread)"
            if Thread.isMainThread {
                MainActor.assumeIsolated {
                    guard let webView else { return }
                    self?.record(event, webView: webView)
                }
            } else {
                DispatchQueue.main.async { [weak self, weak webView] in
                    guard let webView else { return }
                    self?.record(event, webView: webView)
                }
            }
        }
        observations.append(observation)
    }

    func stopObserving() {
        observations.forEach { $0.invalidate() }
        observations.removeAll()
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        record("navigation.didStartProvisional", webView: webView)
    }

    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        record("navigation.didCommit", webView: webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        record("navigation.didFinish", webView: webView)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: any Error) {
        recordFailure("navigation.didFailProvisional", error: error, webView: webView)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        recordFailure("navigation.didFail", error: error, webView: webView)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        record("navigation.webContentProcessDidTerminate", webView: webView)
    }

    private func recordFailure(_ event: String, error: any Error, webView: WKWebView) {
        let error = error as NSError
        record("\(event) domain=\(error.domain) code=\(error.code) error=\(error)", webView: webView)
    }
}

@MainActor
final class WKEngineWebViewTests: XCTestCase, @unchecked Sendable {
    private var delegate: MockWKEngineWebViewDelegate!
    private let testURL = URL(string: "https://www.example.com/")!
    /// Served locally via `loadSimulatedRequest` so the load tests don't depend on network or DNS.
    private static let testPageHTML = """
    <html><head><title>Test Page</title></head><body><h1>Test Page</h1><p>Content</p></body></html>
    """

    @MainActor
    private struct TemporaryLoadObserverFixture {
        let subject: DefaultWKEngineWebView
        let expectations: [XCTestExpectation]
        let diagnostics: TemporaryLoadObserverDiagnostics
        let window: UIWindow?
        let previousKeyWindow: UIWindow?
    }

    override func setUp() async throws {
        try await super.setUp()
        delegate = MockWKEngineWebViewDelegate()
    }

    override func tearDown() async throws {
        delegate = nil
        try await super.tearDown()
    }

    func testNoLeaks() {
        let subject = createSubject()
        subject.close()

        // Wait for webView to fully deallocate
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testLoad_callsObservers() {
        let fixture = makeTemporaryLoadObserverFixture(hosted: false, variant: "baseline-sync-unhosted")
        defer { finishTemporaryLoadObserverFixture(fixture) }

        wait(for: fixture.expectations, timeout: 30)
        fixture.diagnostics.record("wait-returned", webView: fixture.subject)

        XCTAssertGreaterThan(delegate.webViewPropertyChangedCalled, 0)
        XCTAssertNotNil(delegate.lastWebViewPropertyChanged)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testTEMPDiagnosticLoadObservers_asyncUnhosted() async {
        let fixture = makeTemporaryLoadObserverFixture(hosted: false, variant: "TEMP-async-unhosted")
        defer { finishTemporaryLoadObserverFixture(fixture) }

        await fulfillment(of: fixture.expectations, timeout: 30)
        fixture.diagnostics.record("wait-returned", webView: fixture.subject)

        XCTAssertGreaterThan(delegate.webViewPropertyChangedCalled, 0)
        XCTAssertNotNil(delegate.lastWebViewPropertyChanged)
    }

    func testTEMPDiagnosticLoadObservers_syncHosted() {
        let fixture = makeTemporaryLoadObserverFixture(hosted: true, variant: "TEMP-sync-window-hosted")
        defer { finishTemporaryLoadObserverFixture(fixture) }

        wait(for: fixture.expectations, timeout: 30)
        fixture.diagnostics.record("wait-returned", webView: fixture.subject)

        XCTAssertGreaterThan(delegate.webViewPropertyChangedCalled, 0)
        XCTAssertNotNil(delegate.lastWebViewPropertyChanged)
    }

    func testTEMPDiagnosticLoadObservers_asyncHosted() async {
        let fixture = makeTemporaryLoadObserverFixture(hosted: true, variant: "TEMP-async-window-hosted")
        defer { finishTemporaryLoadObserverFixture(fixture) }

        await fulfillment(of: fixture.expectations, timeout: 30)
        fixture.diagnostics.record("wait-returned", webView: fixture.subject)

        XCTAssertGreaterThan(delegate.webViewPropertyChangedCalled, 0)
        XCTAssertNotNil(delegate.lastWebViewPropertyChanged)
    }

    private func makeTemporaryLoadObserverFixture(hosted: Bool, variant: String) -> TemporaryLoadObserverFixture {
        let subject = createSubject()
        let viewportSize = CGSize(width: 320, height: 640)
        subject.frame = CGRect(origin: .zero, size: viewportSize)
        subject.setNeedsLayout()
        subject.layoutIfNeeded()
        let pageHTML = """
        <html><head><meta name="viewport" content="width=device-width,initial-scale=1">
        <title>Test Page</title></head><body style="min-height:2000px">
        <h1>Test Page</h1><p>Content</p></body></html>
        """
        let diagnostics = TemporaryLoadObserverDiagnostics(variant: variant)
        let application = TemporaryLoadObserverDiagnostics.application
        let scene = application?.connectedScenes.compactMap { $0 as? UIWindowScene }.first {
            $0.activationState == .foregroundActive
        }
        let previousKeyWindow = scene?.windows.first(where: \.isKeyWindow)
        let window: UIWindow?
        if hosted {
            diagnostics.record("host-before-window-creation", webView: subject)
            let hostWindow = scene.map(UIWindow.init(windowScene:)) ?? UIWindow(frame: subject.frame)
            hostWindow.frame = subject.frame
            let controller = UIViewController()
            controller.view.addSubview(subject)
            hostWindow.rootViewController = controller
            diagnostics.record("host-before-window-visibility", webView: subject)
            if application != nil {
                hostWindow.makeKeyAndVisible()
            } else {
                hostWindow.isHidden = false
            }
            hostWindow.layoutIfNeeded()
            subject.layoutIfNeeded()
            diagnostics.record("host-after-window-visibility", webView: subject)
            XCTAssertTrue(subject.window === hostWindow, "TEMP diagnostic view must be attached to its fixture window")
            XCTAssertEqual(subject.bounds.size, viewportSize, "TEMP diagnostic viewport must remain controlled")
            window = hostWindow
        } else {
            window = nil
        }
        let loadingExpectation = expectation(that: \WKWebView.isLoading, on: subject) { _, change in
            guard change.newValue != nil else { return false }
            return true
        }
        let titleExpectation = expectation(that: \WKWebView.title, on: subject)
        let urlExpectation = expectation(that: \WKWebView.url, on: subject) { [weak self] _, change in
            guard let url = change.newValue as? URL else { return false }
            XCTAssertEqual(url, self?.testURL)
            return true
        }
        let progressExpectation = expectation(that: \WKWebView.estimatedProgress, on: subject) { _, change in
            guard let progress = change.newValue else { return false }
            XCTAssertGreaterThanOrEqual(progress, 0)
            XCTAssertLessThanOrEqual(progress, 1)
            return progress == 1
        }
        let canGoBackExpectation = expectation(that: \WKWebView.canGoBack, on: subject)
        let canGoForwardExpectation = expectation(that: \WKWebView.canGoForward, on: subject)
        let contentSizeExpectation = expectation(that: \UIScrollView.contentSize, on: subject.scrollView) { _, change in
            guard let size = change.newValue else { return false }
            return size.width > 0 && size.height > viewportSize.height
        }
        let hasOnlySecureContentExpectation = expectation(that: \WKWebView.hasOnlySecureContent, on: subject)

        subject.navigationDelegate = diagnostics
        diagnostics.record("initial-before-load", webView: subject)
        diagnostics.observe(subject)
        let navigation = subject.loadSimulatedRequest(URLRequest(url: testURL), responseHTML: pageHTML)
        diagnostics.record("loadSimulatedRequest-returned navigation=\(navigation != nil)", webView: subject)

        return TemporaryLoadObserverFixture(
            subject: subject,
            expectations: [
                loadingExpectation,
                titleExpectation,
                urlExpectation,
                progressExpectation,
                canGoBackExpectation,
                canGoForwardExpectation,
                contentSizeExpectation,
                hasOnlySecureContentExpectation
            ],
            diagnostics: diagnostics,
            window: window,
            previousKeyWindow: previousKeyWindow
        )
    }

    private func finishTemporaryLoadObserverFixture(_ fixture: TemporaryLoadObserverFixture) {
        fixture.diagnostics.record("final-after-wait", webView: fixture.subject)
        let attachment = XCTAttachment(string: fixture.diagnostics.events.joined(separator: "\n"))
        attachment.name = "TEMP load observers \(fixture.diagnostics.variant)"
        attachment.lifetime = .keepAlways
        add(attachment)
        fixture.diagnostics.stopObserving()
        fixture.subject.navigationDelegate = nil
        if let window = fixture.window {
            window.isHidden = true
            fixture.subject.removeFromSuperview()
            window.rootViewController = nil
            fixture.previousKeyWindow?.makeKey()
        }
    }

    func testLoad_callsBeginRefreshing_onUIRefreshControl() throws {
        let subject = createSubject(pullRefreshViewType: MockUIRefreshControl.self)
        let pullRefresh = try XCTUnwrap(subject.scrollView.refreshControl as? MockUIRefreshControl)

        _ = subject.loadSimulatedRequest(URLRequest(url: testURL), responseHTML: Self.testPageHTML)

        XCTAssertEqual(pullRefresh.beginRefreshingCalled, 1)
        XCTAssertEqual(pullRefresh.endRefreshingCalled, 0)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testInit_setupsPullRefresh() throws {
        let subject = createSubject()

        let pullRefresh = try XCTUnwrap(subject.scrollView.subviews.first {
            $0 is EnginePullRefreshView
        }) as? MockEnginePullRefreshView

        XCTAssertNotNil(pullRefresh)
        XCTAssertNil(subject.scrollView.refreshControl)
        XCTAssertEqual(pullRefresh?.configureCalled, 1)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testInit_withUIRefreshControl_setupsCorrectlyPullRefresh() {
        let subject = createSubject(pullRefreshViewType: UIRefreshControl.self)

        XCTAssertNotNil(subject.scrollView.refreshControl)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testInit_withUIRefreshControlSubclass_doesntConstrainPullRefreshAsSubview() throws {
        let subject = createSubject(pullRefreshViewType: MockUIRefreshControl.self)

        let pullRefresh = try XCTUnwrap(subject.scrollView.refreshControl as? MockUIRefreshControl)
        XCTAssertTrue(pullRefresh.translatesAutoresizingMaskIntoConstraints)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testScrollWillBeginZooming_withUIRefreshControl_removesRefreshControl() {
        let subject = createSubject(pullRefreshViewType: MockUIRefreshControl.self)

        subject.scrollViewWillBeginZooming(UIScrollView(), with: nil)

        XCTAssertNil(subject.scrollView.refreshControl)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testScrollWillBeginZooming_removesPullRefresh() {
        let subject = createSubject()

        subject.scrollViewWillBeginZooming(UIScrollView(), with: nil)

        let pullRefresh = subject.scrollView.subviews.first { $0 is EnginePullRefreshView }
        XCTAssertNil(pullRefresh)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testScrollDidEndZooming_setupsPullRefresh() {
        let subject = createSubject()

        subject.scrollViewWillBeginZooming(UIScrollView(), with: nil)
        subject.scrollViewDidEndZooming(UIScrollView(), with: nil, atScale: 1.0)

        let pullRefresh = subject.scrollView.subviews.first { $0 is EnginePullRefreshView }
        XCTAssertNotNil(pullRefresh)
        XCTAssertNil(subject.scrollView.refreshControl)
        XCTAssertEqual((pullRefresh as? MockEnginePullRefreshView)?.configureCalled, 1)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testScrollDidEndZooming_doesntSetupPullRefreshAgain() {
        let subject = createSubject()

        subject.scrollViewDidEndZooming(UIScrollView(), with: nil, atScale: 1.0)

        let pullRefresh = subject.scrollView.subviews.first { $0 is EnginePullRefreshView }
        XCTAssertNotNil(pullRefresh)
        XCTAssertNil(subject.scrollView.refreshControl)
        XCTAssertEqual((pullRefresh as? MockEnginePullRefreshView)?.configureCalled, 1)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testTriggerPullRefresh_callsDelegate() throws {
        let subject = createSubject()
        let pullRefresh = try XCTUnwrap(subject.scrollView.subviews.first { $0 is EnginePullRefreshView }
                                        as? MockEnginePullRefreshView)

        pullRefresh.onRefresh?()

        XCTAssertEqual(delegate.webViewNeedsReloadCalled, 1)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func createSubject(pullRefreshViewType: EnginePullRefreshViewType = MockEnginePullRefreshView.self,
                       file: StaticString = #filePath,
                       line: UInt = #line) -> DefaultWKEngineWebView {
        let parameters = WKWebViewParameters(blockPopups: true,
                                             isPrivate: false,
                                             autoPlay: .all,
                                             schemeHandler: WKInternalSchemeHandler(),
                                             pullRefreshType: pullRefreshViewType)
        let configuration = DefaultWKEngineConfigurationProvider()
        let subject = DefaultWKEngineWebView(frame: .zero,
                                             configurationProvider: configuration,
                                             parameters: parameters)!
        subject.delegate = delegate
        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }
}
