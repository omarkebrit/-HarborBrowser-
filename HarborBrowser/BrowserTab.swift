import SwiftUI
import WebKit

@MainActor
final class BrowserTab: NSObject, ObservableObject, Identifiable, WKNavigationDelegate, WKUIDelegate {
    let id = UUID()
    let webView: WKWebView
    let isPrivate: Bool
    @Published var title = "New tab"
    @Published var address = ""
    @Published var progress = 0.0
    @Published var loading = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var protection = "Protected"
    @Published var error: String?
    @Published var desktop = false
    @Published var zoom = 1.0
    @Published var findResult = ""
    var pendingURL: URL?
    var preferences: BrowserPreferences
    var rules: [WKContentRuleList]
    var downloads: DownloadManager
    var onChanged: (() -> Void)?
    var onVisited: ((String, URL) -> Void)?
    var onOpen: ((URL, Bool) -> Void)?
    var onOpenRequest: ((URLRequest, Bool) -> Void)?
    var onWindow: ((WKWebViewConfiguration) -> WKWebView?)?
    var onClose: (() -> Void)?
    private var appliedRuleIdentifiers: [String]?
    private var lastRequestedURL: URL?
    private var upgradedHTTPURLs: Set<String> = []
    private var observations: [NSKeyValueObservation] = []
    private var retirementDelegate: SiteDataRetirementDelegate?
    init(isPrivate: Bool, store: WKWebsiteDataStore, rules: [WKContentRuleList], preferences: BrowserPreferences, downloads: DownloadManager, configuration: WKWebViewConfiguration? = nil) {
        self.isPrivate = isPrivate; self.rules = rules; self.preferences = preferences; self.downloads = downloads
        let config = configuration ?? WKWebViewConfiguration()
        config.websiteDataStore = store
        // Keep WebKit's actual device/OS identity while supplying Safari-compatible browser tokens.
        let os = ProcessInfo.processInfo.operatingSystemVersion
        config.applicationNameForUserAgent = "Version/\(os.majorVersion).\(os.minorVersion) Mobile/15E148 Safari/604.1"
        config.userContentController = WKUserContentController()
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = preferences.allowAutoplay ? [] : .all
        config.preferences.javaScriptCanOpenWindowsAutomatically = !preferences.blockPopups
        config.defaultWebpagePreferences.preferredContentMode = .mobile
        webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        zoom = preferences.defaultZoom; webView.pageZoom = zoom
        webView.navigationDelegate = self; webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false; webView.backgroundColor = .systemBackground
        if #available(iOS 16.4, *) { webView.isInspectable = false }
        applyProtection(nil)
        observations = [webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, _ in Task { @MainActor in self?.refresh() } },
                        webView.observe(\.url, options: [.new]) { [weak self] _, _ in Task { @MainActor in self?.refresh() } },
                        webView.observe(\.title, options: [.new]) { [weak self] _, _ in Task { @MainActor in self?.refresh() } },
                        webView.observe(\.isLoading, options: [.new]) { [weak self] _, _ in Task { @MainActor in self?.refresh() } }]
    }
    func refresh() {
        title = webView.title.flatMap { $0.isEmpty ? nil : $0 } ?? webView.url?.host ?? "New tab"
        address = webView.url?.absoluteString ?? pendingURL?.absoluteString ?? lastRequestedURL?.absoluteString ?? ""
        progress = webView.estimatedProgress; loading = webView.isLoading
        canGoBack = webView.canGoBack; canGoForward = webView.canGoForward
        onChanged?()
    }
    func navigate(_ text: String) {
        guard let url = BrowserAddress.resolve(text, engine: preferences.searchEngine, requireHTTPS: preferences.requireHTTPS) else { error = "Enter an HTTP or HTTPS address without a username or password, or a search."; return }
        load(url)
    }
    func load(_ url: URL) {
        loadRequest(URLRequest(url: url))
    }
    func loadRequest(_ original: URLRequest) {
        guard let request = BrowserAddress.requestForNavigation(original, requireHTTPS: preferences.requireHTTPS),
              let destination = request.url else {
            error = "This website address is not supported, or contains a username or password."; return
        }
        upgradedHTTPURLs = []
        if let originalURL = original.url, destination != originalURL { upgradedHTTPURLs.insert(originalURL.absoluteString) }
        pendingURL = nil; lastRequestedURL = destination; address = destination.absoluteString; error = nil; applyProtection(destination)
        webView.load(request)
    }
    func applyProtection(_ url: URL?) {
        let host = url?.host?.lowercased()
        let activeRules: [WKContentRuleList]
        if !preferences.blockAds || (host.map { preferences.disabledHosts.contains($0) } ?? false) { protection = "Protection off"; activeRules = [] }
        else if preferences.videoCompatibility(for: host) { protection = "Video compatibility"; activeRules = [] }
        else { protection = "Protected"; activeRules = rules }
        let identifiers = activeRules.map { $0.identifier ?? String(describing: ObjectIdentifier($0)) }
        // Do not churn a 145k-rule list on every redirect or same-site navigation.
        guard appliedRuleIdentifiers != identifiers else { return }
        let controller = webView.configuration.userContentController
        controller.removeAllContentRuleLists()
        activeRules.forEach { controller.add($0) }
        appliedRuleIdentifiers = identifiers
    }
    func reload() {
        error = nil
        if let url = webView.url {
            if preferences.requireHTTPS && url.scheme?.lowercased() == "http" { load(url) }
            else { upgradedHTTPURLs = []; applyProtection(url); webView.reload() }
        }
        else if let url = lastRequestedURL ?? pendingURL { load(url) }
    }
    func update(preferences: BrowserPreferences, rules: [WKContentRuleList]) {
        self.preferences = preferences; self.rules = rules
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = !preferences.blockPopups
        applyProtection(webView.url ?? lastRequestedURL)
    }
    func setDesktop(_ value: Bool) {
        desktop = value
        let os = ProcessInfo.processInfo.operatingSystemVersion
        webView.customUserAgent = value ? "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(os.majorVersion).\(os.minorVersion) Safari/605.1.15" : nil
        reload()
    }
    func setZoom(_ value: Double) { zoom = value; webView.pageZoom = value }
    func retireForSiteDataRemoval() async -> Bool {
        // A SwiftUI view can temporarily retain a closed tab. Commit a blank
        // document before clearing storage so its old scripts cannot refill it.
        onChanged = nil; onVisited = nil; onOpen = nil; onOpenRequest = nil; onWindow = nil; onClose = nil
        observations.forEach { $0.invalidate() }; observations = []
        webView.stopLoading(); await webView.pauseAllMediaPlayback(); webView.uiDelegate = nil
        let retired = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let delegate = SiteDataRetirementDelegate { continuation.resume(returning: $0) }
            retirementDelegate = delegate
            webView.navigationDelegate = delegate
            delegate.navigation = webView.loadHTMLString("<!doctype html><html><head><title></title></head><body></body></html>", baseURL: nil)
            delegate.startTimeout()
        }
        webView.navigationDelegate = nil; retirementDelegate = nil
        return retired
    }
    func find(_ text: String, backwards: Bool = false) {
        guard !text.isEmpty else { findResult = ""; return }
        let config = WKFindConfiguration(); config.backwards = backwards; config.wraps = true
        webView.find(text, configuration: config) { [weak self] result in self?.findResult = result.matchFound ? "Match found" : "No matches" }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        upgradedHTTPURLs = []; error = nil; refresh()
        if let url = webView.url { onVisited?(title, url) }
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let code = (error as NSError).code
        if code != NSURLErrorCancelled && code != 102 { self.error = error.localizedDescription }
        refresh()
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code != NSURLErrorCancelled { self.error = error.localizedDescription }
        refresh()
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { error = "This tab was stopped by iOS. Tap reload to reopen it."; refresh() }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, preferences page: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        page.preferredContentMode = desktop ? .desktop : .mobile
        page.allowsContentJavaScript = preferences.javaScript
        guard let url = action.request.url, let scheme = url.scheme?.lowercased() else { decisionHandler(.cancel, page); return }
        if ["http", "https"].contains(scheme), BrowserAddress.validated(url) == nil {
            decisionHandler(.cancel, page)
            if action.targetFrame?.isMainFrame != false { error = "This website address is invalid or contains a username or password." }
            return
        }
        if preferences.requireHTTPS && scheme == "http" && action.targetFrame?.isMainFrame != false {
            guard let secureURL = BrowserAddress.validated(url, requireHTTPS: true) else { decisionHandler(.cancel, page); return }
            let method = action.request.httpMethod?.uppercased() ?? "GET"
            if !["GET", "HEAD"].contains(method), action.request.httpBody == nil, action.request.httpBodyStream == nil {
                // WebKit does not always expose a form's body to delegates.
                // Never silently replay a submission without its payload.
                decisionHandler(.cancel, page)
                error = "This form could not be upgraded without losing its submission data. Open the website’s HTTPS address and submit the form there."
                return
            }
            if action.targetFrame == nil {
                // The new tab owns its redirect tracking; opening a popup does
                // not consume an upgrade attempt in the source document.
                decisionHandler(.cancel, page)
                guard action.navigationType == .linkActivated || !preferences.blockPopups else { return }
                var request = action.request
                request.url = secureURL
                onOpenRequest?(request, isPrivate)
                return
            }
            if [.linkActivated, .backForward, .formSubmitted, .formResubmitted].contains(action.navigationType) { upgradedHTTPURLs = [] }
            guard upgradedHTTPURLs.count < 5, upgradedHTTPURLs.insert(url.absoluteString).inserted else {
                decisionHandler(.cancel, page)
                error = "This website redirects back to HTTP. Its page could not be opened with the HTTPS upgrade setting enabled."
                refresh(); return
            }
            decisionHandler(.cancel, page)
            var request = action.request
            request.url = secureURL
            lastRequestedURL = secureURL; address = secureURL.absoluteString; error = nil; applyProtection(secureURL)
            webView.load(request)
            return
        }
        if ["youtube", "vnd.youtube"].contains(scheme) {
            // Ignore automatic app handoffs instead of repeatedly redirecting the current page.
            decisionHandler(.cancel, page)
            if action.navigationType == .linkActivated {
                let input = URLComponents(url: url, resolvingAgainstBaseURL: false)
                let videoID = input?.queryItems?.first(where: { $0.name == "v" })?.value ?? (url.host == "watch" ? nil : url.host)
                var parts = URLComponents(string: "https://www.youtube.com/watch")!
                if let videoID, !videoID.isEmpty {
                    parts.queryItems = [URLQueryItem(name: "v", value: videoID)]
                    if let webURL = parts.url { load(webURL) }
                }
            }
            return
        }
        guard ["http", "https", "about", "blob", "data"].contains(scheme) else {
            decisionHandler(.cancel, page)
            if action.navigationType == .linkActivated, ["mailto", "tel"].contains(scheme) { confirmExternal(url) }
            return
        }
        if action.targetFrame?.isMainFrame == true { applyProtection(url) }
        decisionHandler(action.shouldPerformDownload ? .download : .allow, page)
    }
    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        let mime = response.response.mimeType?.lowercased() ?? ""
        let media = mime.hasPrefix("video/") || mime.hasPrefix("audio/") || ["application/vnd.apple.mpegurl", "application/x-mpegurl"].contains(mime)
        // Iframe player navigations and media belong to WebKit, not the download manager.
        decisionHandler(!response.isForMainFrame || response.canShowMIMEType || media ? .allow : .download)
    }
    func webView(_ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload) { downloads.begin(download) }
    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) { downloads.begin(download) }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard action.navigationType == .linkActivated || !preferences.blockPopups else { return nil }
        return onWindow?(configuration)
    }
    func webViewDidClose(_ webView: WKWebView) { onClose?() }
    private var presenter: UIViewController? {
        var controller = webView.window?.rootViewController
        while let presented = controller?.presentedViewController { controller = presented }
        return controller
    }
    private func confirmExternal(_ url: URL) {
        guard let presenter else { return }
        let alert = UIAlertController(title: "Open another app?", message: url.absoluteString, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Open", style: .default) { _ in UIApplication.shared.open(url) })
        presenter.present(alert, animated: true)
    }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        guard let presenter else { completionHandler(); return }
        let alert = UIAlertController(title: frame.request.url?.host ?? "Website", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() }); presenter.present(alert, animated: true)
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        guard let presenter else { completionHandler(false); return }
        let alert = UIAlertController(title: frame.request.url?.host ?? "Website", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) }); presenter.present(alert, animated: true)
    }
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        guard let presenter else { completionHandler(nil); return }
        let alert = UIAlertController(title: frame.request.url?.host ?? "Website", message: prompt, preferredStyle: .alert)
        alert.addTextField { $0.text = defaultText }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(nil) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak alert] _ in completionHandler(alert?.textFields?.first?.text) }); presenter.present(alert, animated: true)
    }
    func webView(_ webView: WKWebView, contextMenuConfigurationForElement info: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {
        guard let url = info.linkURL, ["http", "https"].contains(url.scheme ?? "") else { completionHandler(nil); return }
        completionHandler(UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            UIMenu(children: [
                UIAction(title: "Open in new tab", image: UIImage(systemName: "plus.square")) { _ in self?.onOpen?(url, self?.isPrivate ?? false) },
                UIAction(title: "Open privately", image: UIImage(systemName: "eye.slash")) { _ in self?.onOpen?(url, true) },
                UIAction(title: "Copy link", image: UIImage(systemName: "doc.on.doc")) { _ in UIPasteboard.general.url = url },
                UIAction(title: "Download link", image: UIImage(systemName: "arrow.down.circle")) { _ in
                    self?.webView.startDownload(using: URLRequest(url: url)) { download in self?.downloads.begin(download) }
                }
            ])
        })
    }
}

@MainActor
private final class SiteDataRetirementDelegate: NSObject, WKNavigationDelegate {
    var navigation: WKNavigation?
    private var completion: ((Bool) -> Void)?
    private var timeout: Task<Void, Never>?
    init(completion: @escaping (Bool) -> Void) { self.completion = completion; super.init() }
    func startTimeout() {
        timeout = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: 5_000_000_000) } catch { return }
            self?.finish(false)
        }
    }
    private func finish(_ retired: Bool) {
        guard let completion else { return }
        self.completion = nil; timeout?.cancel(); timeout = nil
        completion(retired)
    }
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        guard let expected = self.navigation, navigation === expected else { return }
        finish(true)
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        guard let expected = self.navigation, navigation === expected else { return }
        finish(false)
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard let expected = self.navigation, navigation === expected else { return }
        finish(false)
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { finish(true) }
}
