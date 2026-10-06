import SwiftUI
import WebKit

enum SearchEngine: String, Codable, CaseIterable, Identifiable {
    case duckDuckGo = "DuckDuckGo", google = "Google", bing = "Bing", brave = "Brave Search"
    var id: String { rawValue }
    func search(_ query: String) -> URL {
        let base: String
        switch self {
        case .duckDuckGo: base = "https://duckduckgo.com/"
        case .google: base = "https://www.google.com/search"
        case .bing: base = "https://www.bing.com/search"
        case .brave: base = "https://search.brave.com/search"
        }
        var parts = URLComponents(string: base)!
        parts.queryItems = [URLQueryItem(name: "q", value: query)]
        return parts.url!
    }
}
enum AppTheme: String, Codable, CaseIterable, Identifiable {
    case system = "System", light = "Light", dark = "Dark"
    var id: String { rawValue }
    var scheme: ColorScheme? { self == .system ? nil : (self == .dark ? .dark : .light) }
}
struct BrowserPreferences: Codable, Equatable {
    var searchEngine = SearchEngine.duckDuckGo
    var theme = AppTheme.system
    var restoreTabs = true
    var saveHistory = true
    var javaScript = true
    var blockAds = true
    var blockPopups = true
    var youtubeCompatibility = true
    var allowAutoplay = true
    var defaultZoom = 1.0
    var disabledHosts: Set<String> = []
}
struct SavedPage: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var url: String
    var date = Date()
}
struct BrowserSession: Codable { var urls: [String]; var selectedIndex: Int }
struct DownloadItem: Codable, Identifiable {
    var id: UUID
    var name: String
    var relativePath: String
    var state: String
    var date = Date()
    var bytes: Int64 = 0
}
enum BrowserAddress {
    static func resolve(_ input: String, engine: SearchEngine) -> URL? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        if text.contains("://") {
            guard let url = URL(string: text), ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else { return nil }
            return url
        }
        if text.hasPrefix("javascript:") || text.hasPrefix("data:") || text.hasPrefix("file:") { return nil }
        if !text.contains(where: { $0.isWhitespace }), text.contains(".") || text.hasPrefix("localhost") || text.hasPrefix("[") {
            return URL(string: "https://" + text)
        }
        return engine.search(text)
    }
    static func isYouTube(_ host: String?) -> Bool {
        guard let host = host?.lowercased() else { return false }
        return host == "youtube.com" || host.hasSuffix(".youtube.com") || host == "youtu.be"
    }
}
@MainActor
final class BrowserLibrary: ObservableObject {
    @Published var preferences: BrowserPreferences { didSet { write(preferences, "preferences") } }
    @Published var bookmarks: [SavedPage] { didSet { write(bookmarks, "bookmarks") } }
    @Published var history: [SavedPage] { didSet { write(history, "history") } }
    let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        preferences = Self.read(BrowserPreferences.self, "preferences", defaults) ?? BrowserPreferences()
        bookmarks = Self.read([SavedPage].self, "bookmarks", defaults) ?? []
        history = Self.read([SavedPage].self, "history", defaults) ?? []
    }
    private static func read<T: Decodable>(_ type: T.Type, _ key: String, _ defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: "harbor." + key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
    private func write<T: Encodable>(_ value: T, _ key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: "harbor." + key) }
    }
    func visit(title: String, url: URL, isPrivate: Bool) {
        guard !isPrivate, preferences.saveHistory, ["http", "https"].contains(url.scheme ?? "") else { return }
        var items = history.filter { $0.url != url.absoluteString }
        items.insert(SavedPage(title: title, url: url.absoluteString), at: 0)
        history = Array(items.prefix(500))
    }
    func addBookmark(title: String, url: URL) {
        guard !bookmarks.contains(where: { $0.url == url.absoluteString }) else { return }
        bookmarks.insert(SavedPage(title: title, url: url.absoluteString), at: 0)
    }
    func saveSession(_ session: BrowserSession) {
        if preferences.restoreTabs { write(session, "session") } else { defaults.removeObject(forKey: "harbor.session") }
    }
    var session: BrowserSession? { Self.read(BrowserSession.self, "session", defaults) }
}
