// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import WebKit
import WebEngine
import Common

class WebviewViewController: UIViewController,
                             ContentContainable,
                             ScreenshotableView {
    private var webView: WKWebView?
    private var fullscreenObservation: NSKeyValueObservation?
    private var retiringFullscreenWebViews: [ObjectIdentifier: WKWebView] = [:]
    private var retiringFullscreenObservations: [ObjectIdentifier: NSKeyValueObservation] = [:]
#if DEBUG || MOZ_CHANNEL_developer
    private var fullscreenProbeLastSignature: String?
    private var fullscreenProbePlaybackRequestInFlight = false
#endif
    var contentType: ContentType = .webview

    init(webView: WKWebView) {
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        observeFullscreenChanges()
        setupWebView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        releaseCompletedFullscreenWebViews()
        layoutHostedWebView()
#if DEBUG || MOZ_CHANNEL_developer
        if let webView { recordFullscreenProbe("layout", webView: webView) }
#endif
    }

#if DEBUG || MOZ_CHANNEL_developer
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard let webView, #available(iOS 16.0, *),
              webView.fullscreenState != .notInFullscreen || fullscreenProbeLastSignature != nil else { return }
        recordFullscreenProbe("rotation begin target=\(size)", webView: webView, force: true)
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self, let webView = self.webView else { return }
            self.recordFullscreenProbe("rotation complete", webView: webView, force: true)
        }
    }
#endif

    private func setupWebView() {
        guard let webView else { return }
#if DEBUG || MOZ_CHANNEL_developer
        recordFullscreenProbe("setup", webView: webView)
#endif
        if #available(iOS 16.0, *), webView.fullscreenState != .notInFullscreen { return }
        if webView.superview !== view {
#if DEBUG || MOZ_CHANNEL_developer
            recordFullscreenProbe("reparent before", webView: webView)
#endif
            view.addSubview(webView)
#if DEBUG || MOZ_CHANNEL_developer
            recordFullscreenProbe("reparent after", webView: webView)
#endif
        }
        // WebKit moves this view into its own window during element fullscreen.
        webView.translatesAutoresizingMaskIntoConstraints = true
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        layoutHostedWebView()
    }

    private func layoutHostedWebView() {
        guard let webView, webView.superview === view else { return }
        if #available(iOS 16.0, *), webView.fullscreenState != .notInFullscreen { return }
        webView.frame = view.bounds
    }

    private func observeFullscreenChanges() {
        fullscreenObservation = nil
        guard let webView, #available(iOS 16.0, *) else { return }
#if DEBUG || MOZ_CHANNEL_developer
        let options: NSKeyValueObservingOptions = [.old, .new]
#else
        let options: NSKeyValueObservingOptions = []
#endif
        fullscreenObservation = webView.observe(\.fullscreenState, options: options) { [weak self] observedWebView, change in
#if DEBUG || MOZ_CHANNEL_developer
            let transition = "state old=\(String(describing: change.oldValue)) new=\(String(describing: change.newValue))"
#endif
            DispatchQueue.main.async { [weak self] in
#if DEBUG || MOZ_CHANNEL_developer
                self?.recordFullscreenProbe(transition, webView: observedWebView, force: true)
#endif
                self?.setupWebView()
            }
        }
    }

#if DEBUG || MOZ_CHANNEL_developer
    private func recordFullscreenProbe(_ event: String, webView: WKWebView, force: Bool = false) {
        guard #available(iOS 16.0, *) else { return }
        guard force || webView.fullscreenState != .notInFullscreen || fullscreenProbeLastSignature != nil else { return }
        let host = viewIfLoaded
        let signature = [
            "state=\(String(describing: webView.fullscreenState))",
            "web=\(fullscreenProbeIdentity(webView)) frame=\(webView.frame) bounds=\(webView.bounds)",
            "parent=\(fullscreenProbeIdentity(webView.superview)) frame=\(String(describing: webView.superview?.frame))",
            "window=\(fullscreenProbeIdentity(webView.window)) bounds=\(String(describing: webView.window?.bounds))",
            "host=\(fullscreenProbeIdentity(host)) frame=\(String(describing: host?.frame)) "
                + "bounds=\(String(describing: host?.bounds)) window=\(fullscreenProbeIdentity(host?.window))"
        ].joined(separator: " ")
        guard force || signature != fullscreenProbeLastSignature else { return }
        fullscreenProbeLastSignature = signature
        DefaultLogger.shared.log("AsterFullscreenProbe legacy \(event) \(signature)", level: .debug, category: .webview)
        guard !fullscreenProbePlaybackRequestInFlight else { return }
        fullscreenProbePlaybackRequestInFlight = true
        webView.requestMediaPlaybackState { [weak self, weak webView] state in
            guard let self else { return }
            self.fullscreenProbePlaybackRequestInFlight = false
            guard let webView else { return }
            let parent = self.fullscreenProbeIdentity(webView.superview)
            DefaultLogger.shared.log("AsterFullscreenProbe legacy playback=\(String(describing: state)) "
                + "event=\(event) parent=\(parent) request=\(signature)", level: .debug, category: .webview)
        }
    }

    private func fullscreenProbeIdentity(_ view: UIView?) -> String {
        guard let view else { return "nil" }
        return "\(type(of: view))@\(ObjectIdentifier(view))"
    }
#endif

    func update(webView: WKWebView?) {
        let didChangeWebView = self.webView !== webView
        if didChangeWebView, let previousWebView = self.webView {
            if #available(iOS 16.0, *), previousWebView.fullscreenState != .notInFullscreen {
                retainFullscreenWebViewUntilExit(previousWebView)
            } else if previousWebView.superview === viewIfLoaded {
                previousWebView.removeFromSuperview()
            }
        }
        self.webView = webView
        if isViewLoaded {
            if didChangeWebView { observeFullscreenChanges() }
            setupWebView()
        }
    }

    @available(iOS 16.0, *)
    private func retainFullscreenWebViewUntilExit(_ webView: WKWebView) {
        let identifier = ObjectIdentifier(webView)
        retiringFullscreenWebViews[identifier] = webView
        retiringFullscreenObservations[identifier] = webView.observe(\.fullscreenState) { [weak self] _, _ in
            DispatchQueue.main.async { [weak self] in
                self?.releaseCompletedFullscreenWebViews()
            }
        }
    }

    private func releaseCompletedFullscreenWebViews() {
        guard #available(iOS 16.0, *) else { return }
        let completed = retiringFullscreenWebViews.filter { $0.value.fullscreenState == .notInFullscreen }
        for (identifier, previousWebView) in completed {
            if previousWebView !== webView {
                guard previousWebView.superview === viewIfLoaded else { continue }
                previousWebView.removeFromSuperview()
                previousWebView.endEditing(true)
                previousWebView.accessibilityLabel = nil
                previousWebView.accessibilityElementsHidden = true
                previousWebView.accessibilityIdentifier = nil
            }
            retiringFullscreenWebViews.removeValue(forKey: identifier)
            retiringFullscreenObservations.removeValue(forKey: identifier)
        }
    }

    // MARK: - ScreenshotableView

    func getScreenshotData(completionHandler: @escaping (ScreenshotData?) -> Void) {
        guard let webView, let url = webView.url,
              InternalURL(url) == nil else {
            completionHandler(nil)
            return
        }

        var rect = webView.scrollView.frame
        rect.origin.x = webView.scrollView.contentOffset.x
        rect.origin.y = webView.scrollView.contentSize.height - rect.height - webView.scrollView.contentOffset.y

        webView.createPDF { result in
            switch result {
            case .success(let data):
                completionHandler(ScreenshotData(pdfData: data, rect: rect))
            case .failure:
                completionHandler(nil)
            }
        }
    }
}
