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
        layoutHostedWebView()
    }

    private func setupWebView() {
        guard let webView else { return }
        if #available(iOS 16.0, *), webView.fullscreenState != .notInFullscreen { return }
        if webView.superview !== view {
            view.addSubview(webView)
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
        fullscreenObservation = webView.observe(\.fullscreenState) { [weak self] _, _ in
            DispatchQueue.main.async { [weak self] in
                self?.setupWebView()
            }
        }
    }

    func update(webView: WKWebView?) {
        let didChangeWebView = self.webView !== webView
        if didChangeWebView, self.webView?.superview === viewIfLoaded {
            self.webView?.removeFromSuperview()
        }
        self.webView = webView
        if isViewLoaded {
            if didChangeWebView { observeFullscreenChanges() }
            setupWebView()
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
