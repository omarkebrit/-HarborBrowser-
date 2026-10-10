// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

@MainActor
@available(iOS 16.0, *)
final class WKEngineViewTests: XCTestCase {
    private var engineSession: WKEngineSession!

    override func setUp() async throws {
        try await super.setUp()
        engineSession = await MockWKEngineSession()
    }

    override func tearDown() async throws {
        engineSession = nil
        try await super.tearDown()
    }

    func testRenderSetsIsActiveTrue() {
        let subject = createSubject()

        subject.render(session: engineSession)

        XCTAssertTrue(engineSession.isActive)
    }

    func testRenderingSameSession_doesNotDetachOrDuplicateItsWebView() {
        let subject = createSubject()
        subject.frame = CGRect(x: 0, y: 0, width: 320, height: 640)

        subject.render(session: engineSession)
        subject.render(session: engineSession)

        XCTAssertEqual(engineSession.webviewProvider.webView.removeFromSuperviewCalled, 0)
        XCTAssertEqual(subject.subviews.count, 1)
        XCTAssertTrue(subject.constraints.isEmpty)
        XCTAssertTrue(engineSession.webView.translatesAutoresizingMaskIntoConstraints)
        XCTAssertEqual(engineSession.webView.frame, subject.bounds)
    }

    func testHostedWebView_resizesWithItsContainerWithoutBorrowedConstraints() {
        let subject = createSubject()
        subject.render(session: engineSession)

        subject.frame = CGRect(x: 0, y: 0, width: 640, height: 320)
        subject.setNeedsLayout()
        subject.layoutIfNeeded()

        XCTAssertEqual(engineSession.webView.frame, subject.bounds)
        XCTAssertTrue(subject.constraints.isEmpty)
    }

    func testRemoveSetsIsActiveFalse() async {
        let subject = createSubject()
        let newEngineSession = await MockWKEngineSession()

        subject.render(session: engineSession)
        subject.render(session: newEngineSession)

        XCTAssertFalse(engineSession.isActive)
        XCTAssertTrue(newEngineSession.isActive)
    }

    func createSubject() -> WKEngineView {
        let subject = WKEngineView.factory(frame: .zero)
        return subject
    }
}
