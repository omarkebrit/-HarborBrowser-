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
    var onWindow: ((WKWebViewConfiguration) -> WKWebView?)?
    var onClose: (() -> Void)?
    private var observations: [NSKeyValueObservation] = []
    init(isPrivate: Bool, store: WKWebsiteDataStore, rules: [WKContentRuleList], preferences: BrowserPreferences, downloads: DownloadManager, configuration: WKWebViewConfiguration? = nil) {
        self.isPrivate = isPrivate; self.rules = rules; self.preferences = preferences; self.downloads = downloads
        let config = configuration ?? WKWebViewConfiguration()
        config.websiteDataStore = store
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
        address = webView.url?.absoluteString ?? pendingURL?.absoluteString ?? ""
        progress = webView.estimatedProgress; loading = webView.isLoading
        canGoBack = webView.canGoBack; canGoForward = webView.canGoForward
        onChanged?()
    }
    func navigate(_ text: String) {
        guard let url = BrowserAddress.resolve(text, engine: preferences.searchEngine) else { error = "Enter a valid address or search."; return }
        load(url)
    }
    func load(_ url: URL) {
        pendingURL = nil; error = nil; applyProtection(url)
        webView.load(URLRequest(url: url))
    }
    func applyProtection(_ url: URL?) {
        let host = url?.host?.lowercased()
        let controller = webView.configuration.userContentController
        controller.removeAllContentRuleLists()
        if !preferences.blockAds || (host.map { preferences.disabledHosts.contains($0) } ?? false) { protection = "Protection off" }
        else if preferences.youtubeCompatibility && BrowserAddress.isYouTube(host) { protection = "Video compatibility" }
        else { rules.forEach { controller.add($0) }; protection = "Protected" }
    }
    func update(preferences: BrowserPreferences, rules: [WKContentRuleList]) {
        self.preferences = preferences; self.rules = rules
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = !preferences.blockPopups
        applyProtection(webView.url)
    }
    func setDesktop(_ value: Bool) { desktop = value; webView.reload() }
    func setZoom(_ value: Double) { zoom = value; webView.pageZoom = value }
    func find(_ text: String, backwards: Bool = false) {
        guard !text.isEmpty else { findResult = ""; return }
        let config = WKFindConfiguration(); config.backwards = backwards; config.wraps = true
        webView.find(text, configuration: config) { [weak self] result in self?.findResult = result.matchFound ? "Match found" : "No matches" }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        error = nil; refresh()
        if let url = webView.url { onVisited?(title, url) }
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let code = (error as NSError).code
        if code != NSURLErrorCancelled && code != 102 { self.error = error.localizedDescription }
        refresh()
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { self.error = error.localizedDescription; refresh() }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) { error = "This tab was stopped by iOS. Tap reload to reopen it."; refresh() }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, preferences page: WKWebpagePreferences, decisionHandler: @escaping (WKNavigationActionPolicy, WKWebpagePreferences) -> Void) {
        page.preferredContentMode = desktop ? .desktop : .mobile
        page.allowsContentJavaScript = preferences.javaScript
        guard let url = action.request.url, let scheme = url.scheme?.lowercased() else { decisionHandler(.cancel, page); return }
        if ["youtube", "vnd.youtube"].contains(scheme) {
            var parts = URLComponents(); parts.scheme = "https"; parts.host = "www.youtube.com"
            parts.path = "/watch"
            let input = URLComponents(url: url, resolvingAgainstBaseURL: false)
            parts.queryItems = input?.queryItems ?? [URLQueryItem(name: "v", value: url.host)]
            decisionHandler(.cancel, page)
            if let webURL = parts.url { load(webURL) }; return
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
        decisionHandler(response.canShowMIMEType ? .allow : .download)
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
