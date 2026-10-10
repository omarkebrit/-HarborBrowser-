// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

@MainActor
final class WebServerUtilTests: XCTestCase {
    private var mockReaderMode: MockReaderModeHandlers!
    private var mockWebServer: MockWebServer!
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        mockReaderMode = MockReaderModeHandlers()
        mockWebServer = MockWebServer()
        profile = MockProfile()
    }

    override func tearDown() async throws {
        mockReaderMode = nil
        mockWebServer = nil
        profile = nil
        try await super.tearDown()
    }

    func test_setUpWebServer_startsTheServer() {
        let subject = createSubject()

        subject.setUpWebServer()

        XCTAssertEqual(mockWebServer.startIfNeededCalled, 1)
        XCTAssertEqual(mockReaderMode.registerCalled, 1)
    }

    func test_setUpWebServer_registersHandlersOnce_butStartsEachTime() {
        let subject = createSubject()

        subject.setUpWebServer()
        subject.setUpWebServer()
        subject.setUpWebServer()

        // Handlers persist on the server across stop/start, so they're only registered once,
        // but the server is (re)started on every foreground.
        XCTAssertEqual(mockReaderMode.registerCalled, 1)
        XCTAssertEqual(mockWebServer.startIfNeededCalled, 3)
    }

    func testLocalSupportPages_serveBundledHTMLForAuthorizedRoutes() throws {
        createSubject().setUpWebServer()
        let pages = [(SupportUtils.URLForGetHelp, "Aster Help"),
                     (SupportUtils.URLForPrivacyNotice, "Aster privacy information")]

        for (optionalURL, heading) in pages {
            let url = try XCTUnwrap(optionalURL)
            let handler = try XCTUnwrap(InternalSchemeHandler.responders[String(url.path.dropFirst())])
            let request = PrivilegedRequest(url: url) as URLRequest
            let (response, data) = try XCTUnwrap(handler.response(forRequest: request, useOldErrorPage: false))
            let html = try XCTUnwrap(String(data: data, encoding: .utf8))

            XCTAssertEqual(response.url, request.url)
            XCTAssertEqual(response.mimeType, "text/html")
            XCTAssertTrue(html.contains(heading))
            XCTAssertTrue(html.contains("default-src 'none'"))
            XCTAssertNil(html.range(of: "<(script|img|iframe|link)\\b", options: .regularExpression))
        }
    }

    func testLocalSupportPages_rejectUnprivilegedOrUnrelatedRequests() throws {
        createSubject().setUpWebServer()
        let url = try XCTUnwrap(SupportUtils.URLForPrivacyNotice)
        let handler = try XCTUnwrap(InternalSchemeHandler.responders[String(url.path.dropFirst())])

        XCTAssertNil(handler.response(forRequest: URLRequest(url: url), useOldErrorPage: false))
        for invalidURL in ["internal://local/about/aster-help",
                           "internal://other/about/aster-privacy",
                           "https://example.com/about/aster-privacy"] {
            let request = PrivilegedRequest(url: try XCTUnwrap(URL(string: invalidURL))) as URLRequest
            XCTAssertNil(handler.response(forRequest: request, useOldErrorPage: false))
        }
    }

    private func createSubject() -> WebServerUtil {
        return WebServerUtil(
            readerModeHandler: mockReaderMode,
            webServer: mockWebServer,
            profile: profile
        )
    }
}
