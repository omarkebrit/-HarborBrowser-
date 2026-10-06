import Foundation
import WebKit
import CryptoKit

@MainActor
final class BlockingStore {
    private var customURL: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("custom-rules.json")
    }
    func compile(_ data: Data) async throws -> WKContentRuleList {
        guard data.count <= 20_000_000,
              let rules = try JSONSerialization.jsonObject(with: data) as? [[String: Any]],
              !rules.isEmpty, rules.count <= 50_000 else {
            throw NSError(domain: "Harbor", code: 1, userInfo: [NSLocalizedDescriptionKey: "Import a WebKit JSON array with 1–50,000 rules, under 20 MB."])
        }
        let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        guard let json = String(data: data, encoding: .utf8) else { throw CocoaError(.fileReadInapplicableStringEncoding) }
        return try await withCheckedThrowingContinuation { continuation in
            WKContentRuleListStore.default().compileContentRuleList(forIdentifier: "harbor-\(hash)", encodedContentRuleList: json) { list, error in
                if let list { continuation.resume(returning: list) }
                else { continuation.resume(throwing: error ?? CocoaError(.coderInvalidValue)) }
            }
        }
    }
    func load() async throws -> [WKContentRuleList] {
        guard let url = Bundle.main.url(forResource: "baseline", withExtension: "json") else { throw CocoaError(.fileNoSuchFile) }
        let baseline = try await compile(Data(contentsOf: url))
        if FileManager.default.fileExists(atPath: customURL.path) {
            let custom = try await compile(Data(contentsOf: customURL))
            return [baseline, custom]
        }
        return [baseline]
    }
    func importRules(_ url: URL) async throws -> WKContentRuleList {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let list = try await compile(data)
        try data.write(to: customURL, options: .atomic)
        return list
    }
    func resetCustom() throws {
        if FileManager.default.fileExists(atPath: customURL.path) { try FileManager.default.removeItem(at: customURL) }
    }
}
