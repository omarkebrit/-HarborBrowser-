import SwiftUI
import WebKit
import UniformTypeIdentifiers

struct WebSurface: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WKWebView { webView }
    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
struct BrowserScreen: View {
    @EnvironmentObject var browser: BrowserModel
    @State private var showSettings = false
    @State private var showTabs = false
    var body: some View {
        Group {
            if let tab = browser.current {
                TabScreen(tab: tab, showSettings: $showSettings, showTabs: $showTabs).id(tab.id)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "shield.lefthalf.filled").font(.system(size: 60)).foregroundStyle(.mint)
                    Text("Harbor").font(.largeTitle.bold())
                    Text(browser.status).multilineTextAlignment(.center)
                    if browser.busy { ProgressView() }
                    else { Button("Reset imported rules and retry") { Task { await browser.reset() } } }
                }.padding()
            }
        }
        .sheet(isPresented: $showSettings) { SettingsScreen() }
        .sheet(isPresented: $showTabs) {
            NavigationStack {
                List {
                    ForEach(browser.tabs) { tab in
                        Button { browser.selected = tab.id; showTabs = false } label: {
                            Label(tab.title, systemImage: tab.isPrivate ? "eye.slash" : "globe")
                        }.swipeActions { Button("Close", role: .destructive) { browser.close(tab) } }
                    }
                }.navigationTitle("Tabs")
                    .toolbar {
                        ToolbarItem(placement: .bottomBar) { Button("New tab") { browser.addTab(); showTabs = false } }
                        ToolbarItem(placement: .bottomBar) { Button("Private tab") { browser.addTab(isPrivate: true); showTabs = false } }
                        ToolbarItem(placement: .confirmationAction) { Button("Done") { showTabs = false } }
                    }
            }
        }
        .tint(.mint)
    }
}
struct TabScreen: View {
    @EnvironmentObject var browser: BrowserModel
    @ObservedObject var tab: BrowserTab
    @Binding var showSettings: Bool
    @Binding var showTabs: Bool
    @State private var input = ""
    @FocusState private var editing: Bool
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button { browser.toggleShield(tab) } label: {
                    Image(systemName: tab.shield ? "shield.lefthalf.filled" : "shield.slash")
                        .foregroundStyle(tab.shield ? Color.mint : Color.orange)
                }.accessibilityLabel(tab.shield ? "Disable protection for this tab" : "Enable protection for this tab")
                TextField("Search or enter address", text: $input)
                    .keyboardType(.webSearch).textInputAutocapitalization(.never).autocorrectionDisabled()
                    .submitLabel(.go).focused($editing)
                    .onSubmit { tab.load(input); editing = false }
                Button { tab.webView.reload() } label: { Image(systemName: "arrow.clockwise") }.accessibilityLabel("Reload")
            }.padding(12).background(.thinMaterial)
            if tab.progress > 0 && tab.progress < 1 { ProgressView(value: tab.progress).tint(.mint) }
            if let error = tab.error {
                HStack { Text(error).font(.caption); Spacer(); Button("Dismiss") { tab.error = nil } }.padding(10).background(Color.orange.opacity(0.15))
            }
            ZStack {
                WebSurface(webView: tab.webView)
                if tab.address.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: tab.isPrivate ? "eye.slash.fill" : "shield.lefthalf.filled").font(.system(size: 64)).foregroundStyle(.mint)
                        Text(tab.isPrivate ? "Private Harbor" : "Harbor").font(.largeTitle.bold())
                        Text("Browse with fewer ads and trackers.").foregroundStyle(.secondary)
                        Text("Ad and tracking filters enabled. Manage protection in Settings.").font(.caption).multilineTextAlignment(.center).foregroundStyle(.secondary)
                    }.padding().frame(maxWidth: .infinity, maxHeight: .infinity).background(Color(uiColor: .systemBackground))
                }
            }
            HStack {
                Button { tab.webView.goBack() } label: { Image(systemName: "chevron.left") }.disabled(!tab.canGoBack).accessibilityLabel("Back")
                Spacer()
                Button { tab.webView.goForward() } label: { Image(systemName: "chevron.right") }.disabled(!tab.canGoForward).accessibilityLabel("Forward")
                Spacer()
                if let url = tab.webView.url { ShareLink(item: url) { Image(systemName: "square.and.arrow.up") } }
                Spacer()
                Button { showTabs = true } label: { Label("\(browser.tabs.count)", systemImage: "square.on.square") }.accessibilityLabel("Tabs")
                Spacer()
                Button { showSettings = true } label: { Image(systemName: "gearshape") }.accessibilityLabel("Settings")
            }.padding().background(.thinMaterial)
        }
        .onAppear { input = tab.address }
        .onChange(of: tab.address) { value in if !editing { input = value } }
        .onChange(of: editing) { value in if !value { input = tab.address } }
    }
}
struct SettingsScreen: View {
    @EnvironmentObject var browser: BrowserModel
    @Environment(\.dismiss) var dismiss
    @State private var importing = false
    @State private var confirmClear = false
    var body: some View {
        NavigationStack {
            Form {
                Section("Protection") {
                    Text(browser.status).font(.caption)
                    Text(browser.filterDescription)
                    Text("\(browser.ruleCount.formatted()) active rules, including network blocking and ad element hiding. Lists are refreshed when building a new version.")
                    Button("Import WebKit rules (.json)") { importing = true }.disabled(browser.busy)
                    Button("Reset imported rules") { Task { await browser.reset() } }.disabled(browser.busy)
                }
                Section("Filter notices") {
                    Text("AdGuard filter lists, transformed with SafariConverterLib. Original sources and licenses are included in the app bundle. Some advanced filter rules cannot run in WebKit content blocking.").font(.caption)
                }
                Section("Privacy") {
                    Text("Private tabs share a temporary session. Closing all private tabs discards it. This does not hide your IP address.")
                    Button("Clear browsing data", role: .destructive) { confirmClear = true }.disabled(browser.busy)
                }
                Section("About") {
                    Text("Harbor 0.2 — no analytics SDK or account. This prototype has not been tested for Brave-equivalent protection. On-device filter downloads, advanced scriptlets, downloads, fingerprint randomization and guaranteed video-ad removal are not included.").font(.caption)
                }
            }.navigationTitle("Settings")
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
                .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
                    switch result {
                    case .success(let url): Task { await browser.importRules(url) }
                    case .failure(let error): browser.status = error.localizedDescription
                    }
                }
                .confirmationDialog("Clear all cookies and site storage, and close all tabs?", isPresented: $confirmClear, titleVisibility: .visible) {
                    Button("Clear data", role: .destructive) { Task { await browser.clearData() } }
                }
        }
    }
}
