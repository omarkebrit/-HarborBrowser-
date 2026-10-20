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
    private var retiringFullscreenSessions: [ObjectIdentifier: WKEngineSession] = [:]
    private var retiringFullscreenObservations: [ObjectIdentifier: NSKeyValueObservation] = [:]
#if DEBUG
    private var fullscreenProbeLastSignature: String?
    private var fullscreenProbePlaybackRequestInFlight = false
#endif

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
        if #available(iOS 16.0, *), session.webView.fullscreenState != .notInFullscreen {
            retainFullscreenSessionUntilExit(session)
        } else if session.webView.superview === self {
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
#if DEBUG
        if let nativeWebView = webView as? WKWebView {
            recordFullscreenProbe("setup", webView: nativeWebView)
        }
#endif
        if #available(iOS 16.0, *), webView.fullscreenState != .notInFullscreen { return }
        if webView.superview !== self {
#if DEBUG
            if let nativeWebView = webView as? WKWebView {
                recordFullscreenProbe("reparent before", webView: nativeWebView)
            }
#endif
            addSubview(webView)
#if DEBUG
            if let nativeWebView = webView as? WKWebView {
                recordFullscreenProbe("reparent after", webView: nativeWebView)
            }
#endif
        }
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        layoutHostedWebView()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        releaseCompletedFullscreenSessions()
        layoutHostedWebView()
#if DEBUG
        if let webView = session?.webView as? WKWebView {
            recordFullscreenProbe("layout", webView: webView)
        }
#endif
    }

    private func layoutHostedWebView() {
        guard let webView = session?.webView, webView.superview === self else { return }
        if #available(iOS 16.0, *), webView.fullscreenState != .notInFullscreen { return }
        webView.frame = CGRect(x: 0, y: safeAreaInsets.top, width: bounds.width,
                               height: max(0, bounds.height - safeAreaInsets.top - safeAreaInsets.bottom))
    }

    private func observeFullscreenChanges() {
        fullscreenObservation = nil
        guard let webView = session?.webView as? WKWebView, #available(iOS 16.0, *) else { return }
#if DEBUG
        let options: NSKeyValueObservingOptions = [.old, .new]
#else
        let options: NSKeyValueObservingOptions = []
#endif
        fullscreenObservation = webView.observe(\.fullscreenState, options: options) { [weak self] observedWebView, change in
#if DEBUG
            let transition = "state old=\(String(describing: change.oldValue)) new=\(String(describing: change.newValue))"
#endif
            DispatchQueue.main.async { [weak self] in
#if DEBUG
                self?.recordFullscreenProbe(transition, webView: observedWebView, force: true)
#endif
                self?.setupWebViewLayout()
            }
        }
    }

#if DEBUG
    private func recordFullscreenProbe(_ event: String, webView: WKWebView, force: Bool = false) {
        guard #available(iOS 16.0, *) else { return }
        guard force || webView.fullscreenState != .notInFullscreen || fullscreenProbeLastSignature != nil else { return }
        let signature = [
            "state=\(String(describing: webView.fullscreenState))",
            "web=\(fullscreenProbeIdentity(webView)) frame=\(webView.frame) bounds=\(webView.bounds)",
            "parent=\(fullscreenProbeIdentity(webView.superview)) frame=\(String(describing: webView.superview?.frame))",
            "window=\(fullscreenProbeIdentity(webView.window)) bounds=\(String(describing: webView.window?.bounds))",
            "host=\(fullscreenProbeIdentity(self)) frame=\(frame) bounds=\(bounds) "
                + "window=\(fullscreenProbeIdentity(window))"
        ].joined(separator: " ")
        guard force || signature != fullscreenProbeLastSignature else { return }
        fullscreenProbeLastSignature = signature
        logger.log("AsterFullscreenProbe engine \(event) \(signature)", level: .debug, category: .webview)
        guard !fullscreenProbePlaybackRequestInFlight else { return }
        fullscreenProbePlaybackRequestInFlight = true
        webView.requestMediaPlaybackState { [weak self, weak webView] state in
            guard let self else { return }
            self.fullscreenProbePlaybackRequestInFlight = false
            guard let webView else { return }
            let parent = self.fullscreenProbeIdentity(webView.superview)
            self.logger.log("AsterFullscreenProbe engine playback=\(String(describing: state)) "
                + "event=\(event) parent=\(parent) request=\(signature)", level: .debug, category: .webview)
        }
    }

    private func fullscreenProbeIdentity(_ view: UIView?) -> String {
        guard let view else { return "nil" }
        return "\(type(of: view))@\(ObjectIdentifier(view))"
    }
#endif

    @available(iOS 16.0, *)
    private func retainFullscreenSessionUntilExit(_ session: WKEngineSession) {
        let identifier = ObjectIdentifier(session)
        retiringFullscreenSessions[identifier] = session
        guard let webView = session.webView as? WKWebView else { return }
        retiringFullscreenObservations[identifier] = webView.observe(\.fullscreenState) { [weak self] _, _ in
            DispatchQueue.main.async { [weak self] in
                self?.releaseCompletedFullscreenSessions()
            }
        }
    }

    private func releaseCompletedFullscreenSessions() {
        guard #available(iOS 16.0, *) else { return }
        let completed = retiringFullscreenSessions.filter { $0.value.webView.fullscreenState == .notInFullscreen }
        for (identifier, previousSession) in completed {
            if previousSession !== session {
                guard previousSession.webView.superview === self else { continue }
                previousSession.webView.removeFromSuperview()
                sessionlifeCycleManager.deactivate(previousSession)
            }
            retiringFullscreenSessions.removeValue(forKey: identifier)
            retiringFullscreenObservations.removeValue(forKey: identifier)
        }
    }
}
