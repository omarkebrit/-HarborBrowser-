import SwiftUI
import WebKit

@MainActor
final class BrowserModel: ObservableObject {
    @Published var tabs: [BrowserTab] = []
    @Published var selected: UUID?
    @Published var ready = false
    @Published var status = "Preparing protection…"
    @Published var busy = false
    @Published var ruleCount = 0
    @Published var filterDescription = ""
    @Published var recentlyClosed: [SavedPage] = []
    let library: BrowserLibrary
    let downloads = DownloadManager()
    private let blocker = BlockingStore()
    private var rules: [WKContentRuleList] = []
    private var privateStore = WKWebsiteDataStore.nonPersistent()
    private var restoring = false
    var current: BrowserTab? { tabs.first { $0.id == selected } }
    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitest-reset"), let name = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: name)
        }
        #endif
        library = BrowserLibrary()
    }
    func prepare() async {
        guard !ready, !busy else { return }
        busy = true; defer { busy = false }
        do {
            rules = try await blocker.load(); ready = true; refreshFilterStatus()
            restoring = true
            if library.preferences.restoreTabs, let session = library.session, !session.urls.isEmpty {
                for text in session.urls.prefix(20) {
                    let tab = makeTab(isPrivate: false)
                    tab.pendingURL = URL(string: text); tab.refresh()
                }
                selected = tabs[max(0, min(session.selectedIndex, tabs.count - 1))].id
                if let tab = current, let url = tab.pendingURL { tab.load(url) }
            } else { addTab() }
            restoring = false
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--uitest-fixture") { showFixture() }
            if ProcessInfo.processInfo.arguments.contains("--uitest-tabs") {
                for name in ["First", "Second", "Third"] {
                    let fixtureTab = makeTab(isPrivate: false)
                    selected = fixtureTab.id
                    fixtureTab.webView.loadHTMLString("<html><head><title>\(name) tab</title></head><body><h1>\(name) content</h1></body></html>", baseURL: URL(string: "https://fixture.example/\(name.lowercased())"))
                }
            }
            #endif
        } catch { status = "Protection could not load: \(error.localizedDescription)" }
    }
    @discardableResult
    private func makeTab(isPrivate: Bool, configuration: WKWebViewConfiguration? = nil) -> BrowserTab {
        let tab = BrowserTab(isPrivate: isPrivate, store: isPrivate ? privateStore : .default(), rules: rules, preferences: library.preferences, downloads: downloads, configuration: configuration)
        tab.onChanged = { [weak self] in self?.saveSession() }
        tab.onVisited = { [weak self, weak tab] title, url in self?.library.visit(title: title, url: url, isPrivate: tab?.isPrivate ?? true) }
        tab.onOpen = { [weak self] url, privateMode in self?.addTab(isPrivate: privateMode, url: url) }
        tab.onWindow = { [weak self, weak tab] config in
            guard let self, let tab else { return nil }
            let created = self.makeTab(isPrivate: tab.isPrivate, configuration: config)
            self.selected = created.id; return created.webView
        }
        tab.onClose = { [weak self, weak tab] in if let tab { self?.close(tab) } }
        tabs.append(tab); return tab
    }
    func addTab(isPrivate: Bool = false, url: URL? = nil) {
        guard ready, !busy || tabs.isEmpty || restoring else { return }
        let tab = makeTab(isPrivate: isPrivate); selected = tab.id
        if let url { tab.load(url) }; saveSession()
    }
    func select(_ tab: BrowserTab) { selected = tab.id; if let url = tab.pendingURL { tab.load(url) }; saveSession() }
    func open(_ text: String) { current?.navigate(text) }
    func close(_ tab: BrowserTab) {
        if !tab.isPrivate, let url = tab.webView.url { recentlyClosed.insert(SavedPage(title: tab.title, url: url.absoluteString), at: 0); recentlyClosed = Array(recentlyClosed.prefix(10)) }
        tab.webView.stopLoading(); tab.webView.pauseAllMediaPlayback()
        tabs.removeAll { $0.id == tab.id }
        if !tabs.contains(where: { $0.isPrivate }) { privateStore = .nonPersistent() }
        if selected == tab.id, let next = tabs.last { select(next) }
        if tabs.isEmpty { selected = nil; addTab() }
        saveSession()
    }
    func saveSession() {
        guard ready, !restoring else { return }
        let normal = tabs.filter { !$0.isPrivate && ($0.webView.url != nil || $0.pendingURL != nil) }
        let urls = normal.compactMap { ($0.webView.url ?? $0.pendingURL)?.absoluteString }
        library.saveSession(BrowserSession(urls: Array(urls.prefix(20)), selectedIndex: normal.firstIndex { $0.id == selected } ?? 0))
    }
    func applySettings(reload: Bool = true) {
        for tab in tabs { tab.update(preferences: library.preferences, rules: rules); if reload && tab.webView.url != nil { tab.reload() } }
        saveSession()
    }
    func toggleSite(_ host: String) {
        if library.preferences.disabledHosts.contains(host) { library.preferences.disabledHosts.remove(host) }
        else { library.preferences.disabledHosts.insert(host) }
        applySettings()
    }
    func bookmarkCurrent() {
        guard let tab = current, let url = tab.webView.url else { return }
        library.addBookmark(title: tab.title, url: url)
        status = "Bookmark saved"
    }
    private func refreshFilterStatus() {
        ruleCount = blocker.ruleCount; filterDescription = blocker.description
        status = "\(ruleCount.formatted()) filter rules ready"
    }
    func importRules(_ url: URL) async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { rules = [try await blocker.importRules(url)]; refreshFilterStatus(); applySettings() }
        catch { status = "Import failed: \(error.localizedDescription)" }
    }
    func resetRules() async {
        guard !busy else { return }; busy = true; defer { busy = false }
        do { rules = try await blocker.resetCustom(); refreshFilterStatus(); applySettings(); if !ready { ready = true; addTab() } }
        catch { status = error.localizedDescription }
    }
    func clearSiteData() async {
        guard !busy else { return }; busy = true
        tabs.forEach { $0.webView.stopLoading(); $0.webView.pauseAllMediaPlayback() }
        tabs.removeAll(); selected = nil; privateStore = .nonPersistent(); recentlyClosed = []
        library.saveSession(BrowserSession(urls: [], selectedIndex: 0))
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) { continuation.resume() }
        }
        busy = false; addTab(); status = "Cookies and site data cleared"
    }
    #if DEBUG
    func showFixture() {
        let html = "<html><head><title>Harbor Test Page</title><meta name='viewport' content='width=device-width'></head><body><h1>Harbor Test Page</h1><p>Find the lighthouse.</p><button onclick=\"document.getElementById('result').innerText=confirm('Confirm test')?'Confirmed':'Cancelled'\">Confirm test</button><p id='result'></p></body></html>"
        current?.webView.loadHTMLString(html, baseURL: URL(string: "https://harbor-test.example"))
    }
    #endif
}
