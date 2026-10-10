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
    // Upgrade top-level page URLs; this does not rewrite mixed subresources.
    var requireHTTPS = false
    var youtubeCompatibility = true
    var videoCompatibilityHosts: Set<String> = ["erome.com"]
    var allowAutoplay = true
    var defaultZoom = 1.0
    var disabledHosts: Set<String> = []
}
extension BrowserPreferences {
    private enum CodingKeys: String, CodingKey {
        case searchEngine, theme, restoreTabs, saveHistory, javaScript, blockAds, blockPopups, requireHTTPS, youtubeCompatibility, videoCompatibilityHosts, allowAutoplay, defaultZoom, disabledHosts
    }
    init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        searchEngine = try values.decodeIfPresent(SearchEngine.self, forKey: .searchEngine) ?? searchEngine
        theme = try values.decodeIfPresent(AppTheme.self, forKey: .theme) ?? theme
        restoreTabs = try values.decodeIfPresent(Bool.self, forKey: .restoreTabs) ?? restoreTabs
        saveHistory = try values.decodeIfPresent(Bool.self, forKey: .saveHistory) ?? saveHistory
        javaScript = try values.decodeIfPresent(Bool.self, forKey: .javaScript) ?? javaScript
        blockAds = try values.decodeIfPresent(Bool.self, forKey: .blockAds) ?? blockAds
        blockPopups = try values.decodeIfPresent(Bool.self, forKey: .blockPopups) ?? blockPopups
        requireHTTPS = try values.decodeIfPresent(Bool.self, forKey: .requireHTTPS) ?? requireHTTPS
        youtubeCompatibility = try values.decodeIfPresent(Bool.self, forKey: .youtubeCompatibility) ?? youtubeCompatibility
        videoCompatibilityHosts = try values.decodeIfPresent(Set<String>.self, forKey: .videoCompatibilityHosts) ?? videoCompatibilityHosts
        allowAutoplay = try values.decodeIfPresent(Bool.self, forKey: .allowAutoplay) ?? allowAutoplay
        defaultZoom = try values.decodeIfPresent(Double.self, forKey: .defaultZoom) ?? defaultZoom
        disabledHosts = try values.decodeIfPresent(Set<String>.self, forKey: .disabledHosts) ?? disabledHosts
    }
    func videoCompatibility(for host: String?) -> Bool {
        guard let host = host?.lowercased() else { return false }
        return (youtubeCompatibility && BrowserAddress.isYouTube(host)) || videoCompatibilityHosts.contains { host == $0 || host.hasSuffix("." + $0) }
    }
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
    static func resolve(_ input: String, engine: SearchEngine, requireHTTPS: Bool = false) -> URL? {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }
        let lower = text.lowercased()
        if lower.hasPrefix("http://") || lower.hasPrefix("https://") {
            guard !text.contains(where: { $0.isWhitespace }), let url = URL(string: text) else { return nil }
            return validated(url, requireHTTPS: requireHTTPS)
        }

        let authority = String(text.prefix { $0 != "/" && $0 != "?" && $0 != "#" })
        let hostPart = authority.split(separator: ":", maxSplits: 1).first.map(String.init) ?? ""
        let looksLikeHost = hostPart.contains(".") || hostPart.lowercased() == "localhost" || authority.hasPrefix("[")
        if text.range(of: "^[A-Za-z][A-Za-z0-9+.-]*:", options: .regularExpression) != nil {
            // example.com:8080 is a hostname with a port, not a URL scheme.
            let parts = authority.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            let numericPort = parts.count == 2 && !parts[1].isEmpty && parts[1].allSatisfy(\.isNumber)
            guard looksLikeHost && numericPort else { return nil }
        }
        if !text.contains(where: { $0.isWhitespace }), looksLikeHost {
            guard let url = URL(string: "https://" + text) else { return nil }
            return validated(url, requireHTTPS: requireHTTPS)
        }
        return engine.search(text)
    }
    static func validated(_ url: URL, requireHTTPS: Bool = false) -> URL? {
        guard var parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = parts.scheme?.lowercased(), ["http", "https"].contains(scheme),
              parts.user == nil, parts.password == nil,
              let host = parts.host, !BrowserSiteData.normalizedHost(host).isEmpty,
              !host.contains(where: { $0.isWhitespace || $0.isNewline }), !host.contains("@") else { return nil }
        if let port = parts.port, !(1...65535).contains(port) { return nil }
        if requireHTTPS && scheme == "http" {
            parts.scheme = "https"
            if parts.port == 80 { parts.port = nil }
        }
        return parts.url
    }
    static func requestForNavigation(_ request: URLRequest, requireHTTPS: Bool = false) -> URLRequest? {
        guard let url = request.url, let destination = validated(url, requireHTTPS: requireHTTPS) else { return nil }
        var result = request
        result.url = destination
        return result
    }
    static func isYouTube(_ host: String?) -> Bool {
        guard let host = host?.lowercased() else { return false }
        return host == "youtube.com" || host.hasSuffix(".youtube.com") || host == "youtu.be"
    }
}

enum BrowserSiteData {
    private static let suffixRules: PublicSuffixRules? = {
        guard let url = Bundle.main.url(forResource: "PublicSuffixList", withExtension: "dat"),
              let contents = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        let rules = PublicSuffixRules(contents: contents)
        return rules.hasRules ? rules : nil
    }()
    static func normalizedHost(_ value: String) -> String {
        let host = value.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased().trimmingCharacters(in: CharacterSet(charactersIn: ".[]"))
        guard !host.isEmpty, !host.contains(":") else { return host }
        // WK record names and cookie domains can use Unicode while URL hosts
        // use their encoded form. Canonicalize both before comparing labels.
        return URL(string: "https://" + host)?.host?.lowercased() ?? host
    }
    static func matches(_ domain: String, host: String, includeParentDomains: Bool = false) -> Bool {
        let candidate = normalizedHost(domain)
        let host = normalizedHost(host)
        guard !candidate.isEmpty, !host.isEmpty else { return false }
        if candidate == host { return true }
        // IP addresses do not have cookie subdomains or registrable parents.
        func isIPAddress(_ value: String) -> Bool {
            if value.contains(":") { return true }
            let parts = value.split(separator: ".", omittingEmptySubsequences: false)
            return parts.count == 4 && parts.allSatisfy { part in
                guard let number = Int(part) else { return false }
                return (0...255).contains(number) && part.allSatisfy(\.isNumber)
            }
        }
        guard !isIPAddress(candidate), !isIPAddress(host), candidate.contains("."), host.contains(".") else { return false }
        // A shared suffix such as github.io or co.uk is not a shared website.
        // Without the bundled list, only the exact match above is permitted.
        guard let suffixRules,
              let candidateSite = suffixRules.registrableDomain(candidate),
              let hostSite = suffixRules.registrableDomain(host),
              candidateSite == hostSite else { return false }
        return candidate.hasSuffix("." + host) || (includeParentDomains && host.hasSuffix("." + candidate))
    }
}

struct PublicSuffixRules {
    private var exact: Set<String> = []
    private var wildcard: Set<String> = []
    private var exceptions: Set<String> = []
    var hasRules: Bool { !exact.isEmpty || !wildcard.isEmpty || !exceptions.isEmpty }

    init(contents: String) {
        for rawLine in contents.split(whereSeparator: \.isNewline) {
            let line = String(rawLine).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !line.isEmpty, !line.hasPrefix("//") else { continue }
            if line.hasPrefix("!") { exceptions.insert(Self.canonicalHost(String(line.dropFirst()))) }
            else if line.hasPrefix("*.") { wildcard.insert(Self.canonicalHost(String(line.dropFirst(2)))) }
            else { exact.insert(Self.canonicalHost(line)) }
        }
    }

    private static func canonicalHost(_ value: String) -> String {
        BrowserSiteData.normalizedHost(value)
    }

    func registrableDomain(_ value: String) -> String? {
        let host = Self.canonicalHost(value)
        guard !host.contains(":") else { return nil }
        let labels = host.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard labels.count > 1, labels.allSatisfy({ !$0.isEmpty }),
              !(labels.count == 4 && labels.allSatisfy({ $0.allSatisfy(\.isNumber) })) else { return nil }
        var suffixLength = 1 // The PSL's implicit "*" rule for unknown suffixes.
        for start in labels.indices {
            let suffix = labels[start...].joined(separator: ".")
            let length = labels.count - start
            if exceptions.contains(suffix) {
                suffixLength = length - 1
                break
            }
            if exact.contains(suffix) { suffixLength = max(suffixLength, length) }
            if start > 0 && wildcard.contains(suffix) { suffixLength = max(suffixLength, length + 1) }
        }
        guard labels.count > suffixLength else { return nil }
        return labels.suffix(suffixLength + 1).joined(separator: ".")
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
