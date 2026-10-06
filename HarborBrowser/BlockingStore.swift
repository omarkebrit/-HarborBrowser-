import Foundation
import WebKit
import CryptoKit

@MainActor
final class BlockingStore {
    private(set) var ruleCount = 0
    private(set) var description = ""
    private var customURL: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("custom-rules.json")
    }
    private func parse(_ data: Data) throws -> [[String: Any]] {
        guard data.count <= 64_000_000,
              let rules = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              !rules.isEmpty, rules.count <= 150_000 else {
            throw NSError(domain: "Harbor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Use a WebKit JSON array with 1–150,000 rules, under 64 MB."])
        }
        return rules
    }
    private func bundledRules() throws -> [[String: Any]] {
        let enhanced = Bundle.main.url(forResource: "enhanced", withExtension: "json", subdirectory: "Filters")
        guard let url = enhanced ?? Bundle.main.url(forResource: "baseline", withExtension: "json") else { throw CocoaError(.fileNoSuchFile) }
        return try parse(Data(contentsOf: url))
    }
    func compile(_ data: Data) async throws -> WKContentRuleList {
        _ = try parse(data)
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let identifier = "harbor-\(hash)"
        if let cached: WKContentRuleList = await withCheckedContinuation({ continuation in
            WKContentRuleListStore.default().lookUpContentRuleList(forIdentifier: identifier) { list, _ in continuation.resume(returning: list) }
        }) { return cached }
        guard let json = String(data: data, encoding: .utf8) else { throw CocoaError(.fileReadInapplicableStringEncoding) }
        return try await withCheckedThrowingContinuation { continuation in
            WKContentRuleListStore.default().compileContentRuleList(forIdentifier: identifier, encodedContentRuleList: json) { list, error in
                if let list { continuation.resume(returning: list) }
                else { continuation.resume(throwing: error ?? CocoaError(.coderInvalidValue)) }
            }
        }
    }
    private func merged(_ custom: Data?) throws -> Data {
        var rules = try bundledRules()
        if let custom { rules += try parse(custom) }
        guard rules.count <= 150_000 else {
            throw NSError(domain: "Harbor", code: 2, userInfo: [NSLocalizedDescriptionKey: "Combined lists exceed 150,000 rules; import a smaller list."])
        }
        return try JSONSerialization.data(withJSONObject: rules, options: [.sortedKeys])
    }
    private func record(_ data: Data) throws {
        ruleCount = try parse(data).count
        let enhanced = Bundle.main.url(forResource: "enhanced", withExtension: "json", subdirectory: "Filters") != nil
        description = enhanced ? "AdGuard Base + Tracking + Mobile Ads + Popups" : "Starter rules (enhanced pack missing)"
    }
    func load() async throws -> [WKContentRuleList] {
        let custom = FileManager.default.fileExists(atPath: customURL.path) ? try Data(contentsOf: customURL) : nil
        let data = try merged(custom)
        let list = try await compile(data)
        try record(data)
        return [list]
    }
    func importRules(_ url: URL) async throws -> WKContentRuleList {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let custom = try Data(contentsOf: url)
        let data = try merged(custom)
        let list = try await compile(data)
        try custom.write(to: customURL, options: .atomic)
        try record(data)
        return list
    }
    func resetCustom() async throws -> [WKContentRuleList] {
        let data = try merged(nil)
        let list = try await compile(data)
        if FileManager.default.fileExists(atPath: customURL.path) { try FileManager.default.removeItem(at: customURL) }
        try record(data)
        return [list]
    }
}
