import SwiftUI
import WebKit
import UniformTypeIdentifiers
import QuickLook

struct WebSurface: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
struct BrowserScreen: View {
    @EnvironmentObject var browser: BrowserModel
    var body: some View { BrowserShell(browser: browser, library: browser.library) }
}
struct BrowserShell: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var library: BrowserLibrary
    @State private var panel: String?
    var body: some View {
        Group {
            if let tab = browser.current {
                TabScreen(browser: browser, tab: tab, library: library, panel: $panel).id(tab.id)
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "sailboat.fill").font(.system(size: 64)).foregroundStyle(.teal)
                    Text("Harbor").font(.largeTitle.bold())
                    if browser.busy { ProgressView() }
                    Text(browser.status).multilineTextAlignment(.center)
                    if !browser.busy { Button("Retry protection") { Task { await browser.prepare() } } }
                }.padding()
            }
        }
        .tint(.teal)
        .preferredColorScheme(library.preferences.theme.scheme)
        .sheet(isPresented: Binding(get: { panel != nil }, set: { if !$0 { panel = nil } })) {
            NavigationStack {
                Group {
                    switch panel {
                    case "Tabs": TabsPanel(browser: browser)
                    case "Settings": SettingsPanel(browser: browser, library: library)
                    case "Downloads": DownloadsPanel(manager: browser.downloads)
                    case "Site": if let tab = browser.current { SitePanel(browser: browser, tab: tab, library: library) }
                    default: LibraryPanel(browser: browser, library: library)
                    }
                }
                .navigationTitle(panel ?? "Library")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { panel = nil } } }
            }.tint(.teal).preferredColorScheme(library.preferences.theme.scheme)
        }
    }
}
struct TabScreen: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab
    @ObservedObject var library: BrowserLibrary
    @Binding var panel: String?
    @State private var address = ""
    @State private var finding = false
    @State private var query = ""
    @FocusState private var editingAddress: Bool
    var body: some View {
        VStack(spacing: 0) {
            if tab.isPrivate {
                Label("Private browsing", systemImage: "eye.slash.fill").font(.caption.bold()).foregroundStyle(.purple).padding(6)
            }
            ZStack {
                WebSurface(webView: tab.webView)
                if tab.address.isEmpty { home }
            }
            if let error = tab.error {
                HStack { Text(error).font(.caption).lineLimit(3); Spacer(); Button("Retry") { tab.webView.reload() } }.padding(10).background(Color.orange.opacity(0.12))
            }
            if finding {
                HStack {
                    TextField("Find on page", text: $query).onSubmit { tab.find(query) }.accessibilityIdentifier("FindInput")
                    Button { tab.find(query, backwards: true) } label: { Image(systemName: "chevron.up") }.accessibilityLabel("Previous match")
                    Button { tab.find(query) } label: { Image(systemName: "chevron.down") }.accessibilityLabel("Next match")
                    Button { finding = false; query = ""; tab.find("") } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel("Close find")
                }.padding()
                if !tab.findResult.isEmpty { Text(tab.findResult).font(.caption) }
            }
            if tab.loading { ProgressView(value: tab.progress).tint(.teal) }
            VStack(spacing: 12) {
                HStack(spacing: 10) {
                    Button { panel = "Site" } label: {
                        Image(systemName: tab.protection == "Protected" ? "checkmark.shield.fill" : "shield.lefthalf.filled")
                    }.accessibilityLabel("Site controls")
                    TextField("Search or enter address", text: $address)
                        .keyboardType(.webSearch).textInputAutocapitalization(.never).autocorrectionDisabled()
                        .submitLabel(.go).focused($editingAddress).accessibilityIdentifier("Address")
                        .onSubmit { browser.open(address); editingAddress = false }
                    Button {
                        if tab.loading { tab.webView.stopLoading() } else { tab.webView.reload() }
                    } label: { Image(systemName: tab.loading ? "xmark" : "arrow.clockwise") }.accessibilityLabel(tab.loading ? "Stop loading" : "Reload")
                }.padding(12).background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                HStack {
                    Button { tab.webView.goBack() } label: { Image(systemName: "chevron.left") }.disabled(!tab.canGoBack).accessibilityLabel("Back")
                    Spacer()
                    Button { tab.webView.goForward() } label: { Image(systemName: "chevron.right") }.disabled(!tab.canGoForward).accessibilityLabel("Forward")
                    Spacer()
                    Button { browser.addTab(isPrivate: tab.isPrivate) } label: { Image(systemName: "plus") }.accessibilityLabel("New tab")
                    Spacer()
                    Button { panel = "Tabs" } label: { Text("\(browser.tabs.count)").font(.system(size: 14, weight: .semibold)).frame(width: 25, height: 25).overlay(RoundedRectangle(cornerRadius: 6).stroke(lineWidth: 1.5)) }.accessibilityLabel("Tabs")
                    Spacer()
                    Menu {
                        Button { browser.bookmarkCurrent() } label: { Label("Add bookmark", systemImage: "bookmark") }.disabled(tab.webView.url == nil)
                        Button { panel = "Library" } label: { Label("Bookmarks & history", systemImage: "books.vertical") }
                        Button { panel = "Downloads" } label: { Label("Downloads", systemImage: "arrow.down.circle") }
                        Button { finding = true } label: { Label("Find on page", systemImage: "magnifyingglass") }
                        Button { tab.setDesktop(!tab.desktop) } label: { Label(tab.desktop ? "Request mobile site" : "Request desktop site", systemImage: "desktopcomputer") }
                        if let url = tab.webView.url { ShareLink(item: url) { Label("Share page", systemImage: "square.and.arrow.up") } }
                        Button { browser.addTab(isPrivate: true) } label: { Label("New private tab", systemImage: "eye.slash") }
                        Divider()
                        Button { panel = "Settings" } label: { Label("Settings", systemImage: "gearshape") }
                    } label: { Image(systemName: "ellipsis.circle") }.accessibilityIdentifier("BrowserMenu")
                }.font(.title3).padding(.horizontal, 6)
            }.padding(.horizontal, 14).padding(.vertical, 10).background(.regularMaterial)
        }
        .onAppear { address = tab.address }
        .onChange(of: tab.address) { value in if !editingAddress { address = value } }
    }
    private var home: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack { Label("HARBOR", systemImage: "sailboat.fill").font(.headline).tracking(3); Spacer(); Button { panel = "Settings" } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings") }
                VStack(alignment: .leading, spacing: 12) {
                    Text(tab.isPrivate ? "A little more\nprivacy." : "A calmer\nway to browse.").font(.system(size: 42, weight: .bold, design: .rounded))
                    Text(tab.isPrivate ? "Private tabs keep browsing history off this device. Websites and your network can still see activity." : "Your web. With fewer distractions.").foregroundStyle(.secondary)
                }.padding(.vertical, 12)
                Button { editingAddress = true } label: { HStack { Image(systemName: "magnifyingglass"); Text("Search with \(library.preferences.searchEngine.rawValue)"); Spacer(); Image(systemName: "arrow.up.right") }.padding(18).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18)) }
                HStack(spacing: 12) {
                    shortcut("YouTube", "play.rectangle.fill", "https://m.youtube.com")
                    shortcut("Wikipedia", "book.closed.fill", "https://wikipedia.org")
                    shortcut("DuckDuckGo", "magnifyingglass", "https://duckduckgo.com")
                }
                VStack(alignment: .leading, spacing: 8) {
                    Label(library.preferences.blockAds ? "Protection enabled" : "Protection paused", systemImage: "shield.lefthalf.filled").font(.headline)
                    Text("\(browser.ruleCount.formatted()) blocking rules loaded").font(.subheadline).foregroundStyle(.secondary)
                    Text("Video compatibility is available for YouTube.").font(.caption).foregroundStyle(.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(20).background(Color.teal.opacity(0.09), in: RoundedRectangle(cornerRadius: 20))
                if !library.bookmarks.isEmpty {
                    HStack { Text("FAVORITES").font(.caption.bold()).tracking(2); Spacer(); Button("See all") { panel = "Library" } }
                    ForEach(library.bookmarks.prefix(4)) { page in Button { browser.open(page.url) } label: { Label(page.title, systemImage: "bookmark.fill").lineLimit(1).frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6) } }
                }
            }.padding(24)
        }.background(LinearGradient(colors: [Color.teal.opacity(0.13), Color(uiColor: .systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing))
    }
    private func shortcut(_ title: String, _ icon: String, _ url: String) -> some View {
        Button { browser.open(url) } label: { VStack(spacing: 10) { Image(systemName: icon).font(.title2); Text(title).font(.caption).lineLimit(1) }.frame(maxWidth: .infinity).padding(.vertical, 18).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18)) }
    }
}

struct TabsPanel: View {
    @ObservedObject var browser: BrowserModel
    @Environment(\.dismiss) private var dismiss
    @State private var privateMode = false
    var body: some View {
        VStack {
            Picker("Tab type", selection: $privateMode) { Text("Regular").tag(false); Text("Private").tag(true) }.pickerStyle(.segmented).padding()
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(browser.tabs.filter { $0.isPrivate == privateMode }) { tab in
                        TabCard(tab: tab, selected: tab.id == browser.selected, open: { browser.select(tab); dismiss() }, close: { browser.close(tab) })
                    }
                }.padding(.horizontal)
                if !privateMode, let recent = browser.recentlyClosed.first {
                    Button("Reopen closed tab: \(recent.title)") { browser.addTab(url: URL(string: recent.url)); browser.recentlyClosed.removeFirst(); dismiss() }.font(.footnote).padding()
                }
            }
            Button { browser.addTab(isPrivate: privateMode); dismiss() } label: { Label(privateMode ? "New private tab" : "New tab", systemImage: "plus").frame(maxWidth: .infinity).padding() }.buttonStyle(.borderedProminent).padding()
        }.onAppear { privateMode = browser.current?.isPrivate ?? false }
    }
}
struct TabCard: View {
    @ObservedObject var tab: BrowserTab
    let selected: Bool
    let open: () -> Void
    let close: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack { Image(systemName: tab.isPrivate ? "eye.slash" : "globe").foregroundStyle(.teal); Spacer(); Button(action: close) { Image(systemName: "xmark.circle.fill") }.accessibilityLabel("Close \(tab.title)") }
            Button(action: open) {
                VStack(alignment: .leading, spacing: 8) { Text(tab.title).font(.headline).lineLimit(2); Text(tab.webView.url?.host ?? "Start page").font(.caption).foregroundStyle(.secondary).lineLimit(1) }.frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
            }.buttonStyle(.plain)
        }.padding(16).background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18)).overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? Color.teal : .clear, lineWidth: 2))
    }
}
struct LibraryPanel: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var library: BrowserLibrary
    @Environment(\.dismiss) private var dismiss
    @State private var history = false
    @State private var search = ""
    @State private var editPage: SavedPage?
    var pages: [SavedPage] { (history ? library.history : library.bookmarks).filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) || $0.url.localizedCaseInsensitiveContains(search) } }
    var body: some View {
        List {
            Picker("Collection", selection: $history) { Text("Bookmarks").tag(false); Text("History").tag(true) }.pickerStyle(.segmented)
            if pages.isEmpty { Text(history ? "No browsing history" : "No bookmarks yet").foregroundStyle(.secondary) }
            ForEach(pages) { page in
                Button { browser.open(page.url); dismiss() } label: {
                    VStack(alignment: .leading, spacing: 5) { Text(page.title).foregroundStyle(.primary).lineLimit(2); Text(page.url).font(.caption).foregroundStyle(.secondary).lineLimit(1) }
                }
                .swipeActions { Button("Delete", role: .destructive) { if history { library.history.removeAll { $0.id == page.id } } else { library.bookmarks.removeAll { $0.id == page.id } } }; if !history { Button("Edit") { editPage = page }.tint(.teal) } }
            }
        }.searchable(text: $search, prompt: "Search saved pages")
        .sheet(item: $editPage) { page in BookmarkEditor(library: library, page: page, title: page.title, address: page.url) }
    }
}
struct BookmarkEditor: View {
    @ObservedObject var library: BrowserLibrary
    let page: SavedPage
    @State var title: String
    @State var address: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form { TextField("Title", text: $title); TextField("Address", text: $address).textInputAutocapitalization(.never).autocorrectionDisabled() }
                .navigationTitle("Edit bookmark")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }; ToolbarItem(placement: .confirmationAction) { Button("Save") { if let index = library.bookmarks.firstIndex(where: { $0.id == page.id }), let url = BrowserAddress.resolve(address, engine: library.preferences.searchEngine) { library.bookmarks[index].title = title; library.bookmarks[index].url = url.absoluteString; dismiss() } }.disabled(title.isEmpty || address.isEmpty) } }
        }
    }
}
struct DownloadsPanel: View {
    @ObservedObject var manager: DownloadManager
    @State private var preview: URL?
    var body: some View {
        List {
            Section { Text("Downloads stay on this device, including files saved from private tabs. Share a file to save it elsewhere.").font(.footnote).foregroundStyle(.secondary) }
            if manager.items.isEmpty { Label("No downloads yet", systemImage: "arrow.down.circle") }
            ForEach(manager.items) { item in
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.name).font(.headline).lineLimit(2)
                    Text(item.state + (item.bytes > 0 ? " · " + ByteCountFormatter.string(fromByteCount: item.bytes, countStyle: .file) : "")).font(.caption).foregroundStyle(.secondary)
                    if item.state == "Complete" {
                        HStack { Button("Preview") { preview = manager.fileURL(item) }; Spacer(); ShareLink(item: manager.fileURL(item)) { Label("Share", systemImage: "square.and.arrow.up") } }.buttonStyle(.borderless)
                    } else if item.state == "Downloading" { Button("Cancel") { manager.cancel(item) } }
                }.padding(.vertical, 4).swipeActions { Button("Delete", role: .destructive) { manager.remove(item) } }
            }
        }.quickLookPreview($preview)
    }
}
struct SettingsPanel: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var library: BrowserLibrary
    @State private var importing = false
    @State private var clearData = false
    @State private var clearHistory = false
    var body: some View {
        Form {
            Section("Browsing") {
                Picker("Search engine", selection: $library.preferences.searchEngine) { ForEach(SearchEngine.allCases) { Text($0.rawValue).tag($0) } }
                Picker("Appearance", selection: $library.preferences.theme) { ForEach(AppTheme.allCases) { Text($0.rawValue).tag($0) } }
                Toggle("Restore regular tabs", isOn: $library.preferences.restoreTabs)
                Toggle("Save browsing history", isOn: $library.preferences.saveHistory)
                Stepper("New tab zoom: \(Int(library.preferences.defaultZoom * 100))%", value: $library.preferences.defaultZoom, in: 0.5...2.0, step: 0.1)
            }
            Section {
                Toggle("Block ads & trackers", isOn: $library.preferences.blockAds)
                Toggle("Block automatic pop-ups", isOn: $library.preferences.blockPopups)
                Toggle("JavaScript", isOn: $library.preferences.javaScript)
                if !library.preferences.disabledHosts.isEmpty {
                    NavigationLink("Site exceptions (\(library.preferences.disabledHosts.count))") {
                        List { ForEach(library.preferences.disabledHosts.sorted(), id: \.self) { host in Text(host).swipeActions { Button("Remove", role: .destructive) { library.preferences.disabledHosts.remove(host) } } } }.navigationTitle("Site exceptions")
                    }
                }
            } header: { Text("Privacy & protection") } footer: { Text("Disabling JavaScript can break video players and sign-in pages. Private tabs do not save history or restore after closing Harbor.") }
            Section {
                Toggle("YouTube compatibility", isOn: $library.preferences.youtubeCompatibility)
                Toggle("Allow media autoplay", isOn: $library.preferences.allowAutoplay)
            } header: { Text("Video & audio") } footer: { Text("YouTube compatibility pauses content filtering on YouTube to avoid player failures; ads may appear. Autoplay changes apply to new tabs. Inline playback, AirPlay and Picture in Picture are enabled when supported by the website and iOS.") }
            Section("Filter lists") {
                LabeledContent("Loaded rules", value: browser.ruleCount.formatted())
                Text(browser.filterDescription).font(.caption).foregroundStyle(.secondary)
                Button("Import WebKit rules (.json)") { importing = true }.disabled(browser.busy)
                Button("Remove custom filters") { Task { await browser.resetRules() } }.disabled(browser.busy)
                Text(browser.status).font(.caption)
            }
            Section("Your data") {
                Button("Clear browsing history", role: .destructive) { clearHistory = true }
                Button("Clear cookies & website data", role: .destructive) { clearData = true }.disabled(browser.busy)
            }
            Section { LabeledContent("Harbor", value: "0.3"); Text("Built for a calmer web. Filter lists refresh when a new app build is installed.").font(.footnote).foregroundStyle(.secondary) }
        }
        .onDisappear { browser.applySettings() }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in if case .success(let url) = result { Task { await browser.importRules(url) } } }
        .confirmationDialog("Delete browsing history?", isPresented: $clearHistory, titleVisibility: .visible) { Button("Clear history", role: .destructive) { library.history = [] } }
        .confirmationDialog("Clear website data and close all tabs? You will be signed out of websites. Bookmarks and downloads stay saved.", isPresented: $clearData, titleVisibility: .visible) { Button("Clear website data", role: .destructive) { Task { await browser.clearSiteData() } } }
    }
}
struct SitePanel: View {
    @ObservedObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab
    @ObservedObject var library: BrowserLibrary
    var body: some View {
        Form {
            Section {
                Label(tab.webView.url?.host ?? "New tab", systemImage: tab.webView.url?.scheme == "https" ? "lock.fill" : "globe")
                LabeledContent("Protection", value: tab.protection)
                if let host = tab.webView.url?.host?.lowercased() {
                    Toggle("Protection for this site", isOn: Binding(get: { !library.preferences.disabledHosts.contains(host) }, set: { _ in browser.toggleSite(host) })).disabled(!library.preferences.blockAds)
                    if BrowserAddress.isYouTube(host) { Toggle("YouTube compatibility", isOn: $library.preferences.youtubeCompatibility).onChange(of: library.preferences.youtubeCompatibility) { _ in browser.applySettings() }; Text("Content filters are paused in compatibility mode. Ads may appear.").font(.caption).foregroundStyle(.secondary) }
                }
            }
            Section("Page display") {
                Toggle("Desktop site", isOn: Binding(get: { tab.desktop }, set: { tab.setDesktop($0) }))
                Stepper("Page zoom: \(Int(tab.zoom * 100))%", value: Binding(get: { tab.zoom }, set: { tab.setZoom($0) }), in: 0.5...2.0, step: 0.1)
                Button("Reset zoom") { tab.setZoom(1) }
            }
        }
    }
}
