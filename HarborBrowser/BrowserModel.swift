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
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var shield = true
    @Published var error: String?
    private var observations: [NSKeyValueObservation] = []
    init(isPrivate: Bool, store: WKWebsiteDataStore, rules: [WKContentRuleList]) {
        self.isPrivate = isPrivate
        let config = WKWebViewConfiguration()
        config.websiteDataStore = store
        for list in rules { config.userContentController.add(list) }
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        config.allowsInlineMediaPlayback = true
        webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        observations = [webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, _ in Task { @MainActor in self?.refresh() } },
                        webView.observe(\.url, options: [.new]) { [weak self] _, _ in Task { @MainActor in self?.refresh() } },
                        webView.observe(\.title, options: [.new]) { [weak self] _, _ in Task { @MainActor in self?.refresh() } }]
    }
    func refresh() {
        title = webView.title ?? "New tab"
        address = webView.url?.absoluteString ?? ""
        progress = webView.estimatedProgress
        canGoBack = webView.canGoBack; canGoForward = webView.canGoForward
    }
    func load(_ input: String) {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return }
        var url: URL?
        if value.contains("://") {
            url = URL(string: value)
        } else if value.contains(".") && !value.contains(where: { $0.isWhitespace }) {
            url = URL(string: "https://" + value)
        } else {
            var components = URLComponents(string: "https://duckduckgo.com/")!
            components.queryItems = [URLQueryItem(name: "q", value: value)]
            url = components.url
        }
        guard let url, ["https", "http"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else {
            error = "Enter a valid HTTP or HTTPS address."; return
        }
        error = nil
        webView.load(URLRequest(url: url))
    }
    func apply(_ rules: [WKContentRuleList]) {
        webView.configuration.userContentController.removeAllContentRuleLists()
        if shield { rules.forEach { webView.configuration.userContentController.add($0) } }
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { refresh() }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code != NSURLErrorCancelled { self.error = error.localizedDescription }
        refresh()
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { self.error = error.localizedDescription; refresh() }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let scheme = action.request.url?.scheme?.lowercased(), ["http", "https", "about"].contains(scheme) else { decisionHandler(.cancel); return }
        decisionHandler(.allow)
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for action: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if action.navigationType == .linkActivated, action.targetFrame == nil { webView.load(action.request) }
        return nil
    }
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) { error = message; completionHandler() }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) { completionHandler(false) }
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) { completionHandler(nil) }
}

@MainActor
final class BrowserModel: ObservableObject {
    @Published var tabs: [BrowserTab] = []
    @Published var selected: UUID?
    @Published var ready = false
    @Published var status = "Preparing protection…"
    @Published var busy = false
    private let blocker = BlockingStore()
    private var rules: [WKContentRuleList] = []
    private var privateStore = WKWebsiteDataStore.nonPersistent()
    var current: BrowserTab? { tabs.first { $0.id == selected } }
    func prepare() async {
        guard !ready, !busy else { return }
        busy = true; defer { busy = false }
        do { rules = try await blocker.load(); ready = true; status = "Baseline protection ready"; addTab() }
        catch { status = "Protection failed: \(error.localizedDescription). Reset imported rules and retry." }
    }
    func addTab(isPrivate: Bool = false) {
        guard ready else { return }
        let tab = BrowserTab(isPrivate: isPrivate, store: isPrivate ? privateStore : .default(), rules: rules)
        tabs.append(tab); selected = tab.id
    }
    func close(_ tab: BrowserTab) {
        tab.webView.stopLoading()
        tabs.removeAll { $0.id == tab.id }
        if !tabs.contains(where: { $0.isPrivate }) { privateStore = .nonPersistent() }
        if selected == tab.id { selected = tabs.last?.id }
        if tabs.isEmpty { addTab() }
    }
    func toggleShield(_ tab: BrowserTab) { tab.shield.toggle(); tab.apply(rules); tab.webView.reload() }
    func importRules(_ url: URL) async {
        guard !busy else { return }
        busy = true; defer { busy = false }
        do {
            let custom = try await blocker.importRules(url)
            rules = Array(rules.prefix(1)) + [custom]
            for tab in tabs { tab.apply(rules); tab.webView.reload() }
            status = "Imported rules active; pages reloaded"
        } catch { status = "Import failed: \(error.localizedDescription)" }
    }
    func reset() async {
        guard !busy else { return }
        do {
            try blocker.resetCustom()
            if ready {
                rules = Array(rules.prefix(1)); tabs.forEach { $0.apply(rules); $0.webView.reload() }
                status = "Baseline protection ready"
            } else { await prepare() }
        } catch { status = error.localizedDescription }
    }
    func clearData() async {
        guard !busy else { return }
        busy = true; defer { busy = false }
        tabs.forEach { $0.webView.stopLoading() }
        tabs.removeAll(); selected = nil; privateStore = .nonPersistent()
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) { continuation.resume() }
        }
        addTab(); status = "Browsing data cleared"
    }
}
