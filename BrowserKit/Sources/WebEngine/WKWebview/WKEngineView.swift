// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import WebKit

final class WKEngineView: UIView, EngineView {
    private var session: WKEngineSession?
    private var logger: Logger
    private var sessionlifeCycleManager: WKSessionLifecycleManager
    private var fullscreenObservation: NSKeyValueObservation?

    // TODO: FXIOS-13670 With Swift 6 we can use default params in the init
    @MainActor
    public static func factory(frame: CGRect) -> WKEngineView {
        let sessionlifeCycleManager = DefaultWKSessionLifecycleManager()
        let logger = DefaultLogger.shared
        return WKEngineView(
            frame: frame,
            sessionlifeCycleManager: sessionlifeCycleManager,
            logger: logger
        )
    }

    @MainActor
    init(frame: CGRect,
         sessionlifeCycleManager: WKSessionLifecycleManager,
         logger: Logger) {
        self.sessionlifeCycleManager = sessionlifeCycleManager
        self.logger = logger
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func render(session: EngineSession) {
        if let currentSession = self.session, let nextSession = session as? WKEngineSession,
           currentSession === nextSession {
            setupWebViewLayout()
            return
        }
        if let currentSession = self.session {
            remove(session: currentSession)
        }

        guard let session = session as? WKEngineSession else {
            logger.log("Adding a session that is not of type WKEngineSession in WKEngineView, that is not permitted",
                       level: .debug,
                       category: .webview)
            return
        }

        add(session: session)
    }

    private func remove(session: WKEngineSession) {
        fullscreenObservation = nil
        if session.webView.superview === self {
            session.webView.removeFromSuperview()
        }
        sessionlifeCycleManager.deactivate(session)
    }

    private func add(session: WKEngineSession) {
        self.session = session
        sessionlifeCycleManager.activate(session)
        observeFullscreenChanges()
        setupWebViewLayout()
    }

    private func setupWebViewLayout() {
        guard let session else { return }

        let webView = session.webView
        if #available(iOS 16.0, *), let nativeWebView = webView as? WKWebView,
           nativeWebView.fullscreenState != .notInFullscreen { return }
        if webView.superview !== self {
            addSubview(webView)
        }
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        layoutHostedWebView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutHostedWebView()
    }

    private func layoutHostedWebView() {
        guard let webView = session?.webView, webView.superview === self else { return }
        if #available(iOS 16.0, *), let nativeWebView = webView as? WKWebView,
           nativeWebView.fullscreenState != .notInFullscreen { return }
        webView.frame = CGRect(x: 0, y: safeAreaInsets.top, width: bounds.width,
                               height: max(0, bounds.height - safeAreaInsets.top - safeAreaInsets.bottom))
    }

    private func observeFullscreenChanges() {
        fullscreenObservation = nil
        guard let webView = session?.webView as? WKWebView, #available(iOS 16.0, *) else { return }
        fullscreenObservation = webView.observe(\.fullscreenState) { [weak self] _, _ in
            DispatchQueue.main.async { [weak self] in
                self?.setupWebViewLayout()
            }
        }
    }
}
