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
    init(defaults: UserDefaults = .standard) {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--uitest-reset"), let name = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: name)
        }
        #endif
        library = BrowserLibrary(defaults: defaults)
    }
    func prepare() async {
        guard !ready, !busy else { return }
        busy = true; defer { busy = false }
        do {
            rules = try await blocker.load(); refreshFilterStatus()
        } catch {
            rules = []; ruleCount = 0; filterDescription = "Protection unavailable"
            status = "Filters could not load. Browsing is available without protection; retry from Settings."
        }
        ready = true
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
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "--uitest-video-page"), arguments.indices.contains(index + 1),
           let url = URL(string: arguments[index + 1]), url.host == "127.0.0.1" {
            current?.load(url)
        }
        #endif
    }
    @discardableResult
    private func makeTab(isPrivate: Bool, configuration: WKWebViewConfiguration? = nil, store: WKWebsiteDataStore? = nil, id: UUID = UUID()) -> BrowserTab {
        let tab = BrowserTab(isPrivate: isPrivate, store: store ?? (isPrivate ? privateStore : .default()), rules: rules, preferences: library.preferences, downloads: downloads, configuration: configuration, id: id)
        tab.onChanged = { [weak self] in self?.saveSession() }
        tab.onVisited = { [weak self, weak tab] title, url in self?.library.visit(title: title, url: url, isPrivate: tab?.isPrivate ?? true) }
        tab.onOpen = { [weak self] url, privateMode in self?.addTab(isPrivate: privateMode, url: url) }
        tab.onOpenRequest = { [weak self] request, privateMode in
            guard let self, self.ready, !self.busy else { return }
            let created = self.makeTab(isPrivate: privateMode)
            self.selected = created.id; created.loadRequest(request); self.saveSession()
        }
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
    func open(_ text: String) { guard !busy else { return }; current?.navigate(text) }
    func close(_ tab: BrowserTab) {
        if !tab.isPrivate, let url = tab.webView.url, BrowserAddress.validated(url) != nil { recentlyClosed.insert(SavedPage(title: tab.title, url: url.absoluteString), at: 0); recentlyClosed = Array(recentlyClosed.prefix(10)) }
        tab.webView.stopLoading(); tab.webView.pauseAllMediaPlayback(); tab.webView.closeAllMediaPresentations(completionHandler: nil)
        tabs.removeAll { $0.id == tab.id }
        if !tabs.contains(where: { $0.isPrivate }) { privateStore = .nonPersistent() }
        if selected == tab.id, let next = tabs.last { select(next) }
        if tabs.isEmpty { selected = nil; addTab() }
        saveSession()
    }
    func saveSession() {
        guard ready, !restoring else { return }
        let normal = tabs.filter { !$0.isPrivate && ($0.webView.url ?? $0.pendingURL).flatMap { BrowserAddress.validated($0) } != nil }
        let urls = normal.compactMap { ($0.webView.url ?? $0.pendingURL)?.absoluteString }
        library.saveSession(BrowserSession(urls: Array(urls.prefix(20)), selectedIndex: normal.firstIndex { $0.id == selected } ?? 0))
    }
    func applySettings(reload: Bool = true) {
        for tab in tabs {
            if tab.needsRecreation(for: library.preferences) {
                recreate(tab)
            } else {
                tab.update(preferences: library.preferences, rules: rules)
                if reload && tab.webView.url != nil { tab.reload() }
            }
        }
        saveSession()
    }
    private func recreate(_ tab: BrowserTab) {
        guard let index = tabs.firstIndex(where: { $0 === tab }) else { return }
        let request = tab.currentRequestForRecreation
        guard request != nil || tab.address.isEmpty || tab.pendingURL != nil else {
            tab.update(preferences: library.preferences, rules: rules)
            tab.error = "Open a new tab to apply playback and pop-up settings. This submitted page was kept to avoid repeating its form."
            return
        }
        let replacement = makeTab(isPrivate: tab.isPrivate, store: tab.webView.configuration.websiteDataStore, id: tab.id)
        tabs.removeLast()
        tabs[index] = replacement
        tab.onChanged = nil; tab.onVisited = nil; tab.onOpen = nil; tab.onOpenRequest = nil; tab.onWindow = nil; tab.onClose = nil
        tab.webView.stopLoading(); tab.webView.pauseAllMediaPlayback(); tab.webView.closeAllMediaPresentations(completionHandler: nil)
        tab.webView.navigationDelegate = nil; tab.webView.uiDelegate = nil
        if tab.desktop { replacement.setDesktop(true, reloadPage: false) }
        replacement.setZoom(tab.zoom)
        if let request { replacement.loadRequest(request) }
        else if let url = tab.pendingURL { replacement.pendingURL = url; replacement.refresh() }
    }
    func reloadCurrentForVideo() {
        guard !busy, let tab = current, let host = tab.webView.url?.host?.lowercased() else { return }
        library.preferences.javaScript = true
        library.preferences.allowAutoplay = true
        library.preferences.videoCompatibilityHosts.insert(host)
        tab.setDesktop(false, reloadPage: false)
        applySettings()
        status = "Video compatibility enabled for \(host); filtering is paused on this site."
    }
    func openPlaybackCheck() {
        guard ready, !busy, let url = Bundle.main.url(forResource: "PlaybackCheck", withExtension: "html"),
              let html = try? String(contentsOf: url, encoding: .utf8) else { return }
        let tab = makeTab(isPrivate: current?.isPrivate ?? false)
        var checkPreferences = library.preferences
        checkPreferences.javaScript = true
        tab.update(preferences: checkPreferences, rules: rules)
        selected = tab.id
        tab.webView.loadHTMLString(html, baseURL: nil)
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
        status = blocker.warning ?? "\(ruleCount.formatted()) filter rules ready"
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
        tabs.forEach { $0.webView.stopLoading(); $0.webView.pauseAllMediaPlayback(); $0.webView.closeAllMediaPresentations(completionHandler: nil) }
        tabs.removeAll(); selected = nil; privateStore = .nonPersistent(); recentlyClosed = []
        library.saveSession(BrowserSession(urls: [], selectedIndex: 0))
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            WKWebsiteDataStore.default().removeData(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), modifiedSince: .distantPast) { continuation.resume() }
        }
        busy = false; addTab(); status = "Cookies and site data cleared"
    }
    func clearCurrentSiteData() async {
        guard !busy, let tab = current, let host = tab.webView.url?.host else { return }
        busy = true; defer { busy = false }
        let store = tab.webView.configuration.websiteDataStore
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        let records = await withCheckedContinuation { (continuation: CheckedContinuation<[WKWebsiteDataRecord], Never>) in
            store.fetchDataRecords(ofTypes: types) { continuation.resume(returning: $0) }
        }
        // WebKit can group storage by a parent domain. Never use an unbounded
        // suffix match: example.com must not match notexample.com.
        let matchingRecords = records.filter { BrowserSiteData.matches($0.displayName, host: host, includeParentDomains: true) }
        let groupedHosts = matchingRecords.map(\.displayName)
        let affectedTabs = tabs.filter { candidate in
            guard candidate.webView.configuration.websiteDataStore === store,
                  let candidateHost = candidate.webView.url?.host ?? candidate.pendingURL?.host else { return false }
            return BrowserSiteData.matches(candidateHost, host: host, includeParentDomains: true)
                || groupedHosts.contains { BrowserSiteData.matches(candidateHost, host: $0) }
        }
        // Closing affected pages prevents running scripts from immediately
        // repopulating storage while it is being removed.
        affectedTabs.forEach { close($0) }
        for affectedTab in affectedTabs {
            guard await affectedTab.retireForSiteDataRemoval() else {
                status = "Site tabs closed, but stored data could not be cleared safely. Try again after reopening the website."
                return
            }
        }
        // Refresh after retiring documents to include writes that completed
        // while the original pages were shutting down.
        let remainingRecords = await withCheckedContinuation { (continuation: CheckedContinuation<[WKWebsiteDataRecord], Never>) in
            store.fetchDataRecords(ofTypes: types) { continuation.resume(returning: $0) }
        }
        let recordsToRemove = remainingRecords.filter { BrowserSiteData.matches($0.displayName, host: host, includeParentDomains: true) }
        let storageTypes = types.subtracting([WKWebsiteDataTypeCookies])
        if !recordsToRemove.isEmpty {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                store.removeData(ofTypes: storageTypes, for: recordsToRemove) { continuation.resume() }
            }
        }
        let cookies = await withCheckedContinuation { (continuation: CheckedContinuation<[HTTPCookie], Never>) in
            store.httpCookieStore.getAllCookies { continuation.resume(returning: $0) }
        }
        for cookie in cookies where BrowserSiteData.matches(cookie.domain, host: host, includeParentDomains: true) {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                store.httpCookieStore.delete(cookie) { continuation.resume() }
            }
        }
        saveSession()
        status = "Stored data cleared for \(host); matching site tabs closed"
    }
    #if DEBUG
    func showFixture() {
        let html = "<html><head><title>Harbor Test Page</title><meta name='viewport' content='width=device-width'></head><body><h1>Harbor Test Page</h1><p>Find the lighthouse.</p><button onclick=\"document.getElementById('result').innerText=confirm('Confirm test')?'Confirmed':'Cancelled'\">Confirm test</button><p id='result'></p></body></html>"
        current?.webView.loadHTMLString(html, baseURL: URL(string: "https://harbor-test.example"))
    }
    #endif
}
