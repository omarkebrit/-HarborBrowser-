import Foundation
import Combine
import WebKit

@MainActor
final class DownloadManager: NSObject, ObservableObject, WKDownloadDelegate {
    @Published var items: [DownloadItem] = []
    private var active: [ObjectIdentifier: (WKDownload, UUID)] = [:]
    private var records: URL { directory.appendingPathComponent("index.json") }
    var directory: URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Downloads")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    override init() {
        super.init()
        if let data = try? Data(contentsOf: records), let saved = try? JSONDecoder().decode([DownloadItem].self, from: data) {
            items = saved.map { item in var item = item; if item.state == "Downloading" { item.state = "Interrupted" }; return item }
        }
    }
    func begin(_ download: WKDownload) { download.delegate = self }
    func fileURL(_ item: DownloadItem) -> URL { directory.appendingPathComponent(item.relativePath) }
    func persist() { if let data = try? JSONEncoder().encode(items) { try? data.write(to: records, options: .atomic) } }
    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse, suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let id = UUID()
        let candidate = (suggestedFilename as NSString).lastPathComponent
        let name = candidate.isEmpty || candidate == "." || candidate == ".." ? "download" : String(candidate.prefix(160))
        let folder = directory.appendingPathComponent(id.uuidString)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            items.insert(DownloadItem(id: id, name: name, relativePath: id.uuidString + "/" + name, state: "Downloading"), at: 0)
            active[ObjectIdentifier(download)] = (download, id)
            persist(); completionHandler(folder.appendingPathComponent(name))
        } catch { completionHandler(nil) }
    }
    func downloadDidFinish(_ download: WKDownload) {
        guard let (_, id) = active.removeValue(forKey: ObjectIdentifier(download)), let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].state = "Complete"
        let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL(items[index]).path)
        items[index].bytes = (attributes?[.size] as? NSNumber)?.int64Value ?? 0
        persist()
    }
    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        guard let (_, id) = active.removeValue(forKey: ObjectIdentifier(download)), let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].state = "Failed: " + error.localizedDescription; persist()
    }
    func cancel(_ item: DownloadItem) {
        guard let entry = active.first(where: { $0.value.1 == item.id }) else { return }
        entry.value.0.cancel { _ in }
        active.removeValue(forKey: entry.key)
        if let index = items.firstIndex(where: { $0.id == item.id }) { items[index].state = "Cancelled" }
        persist()
    }
    func remove(_ item: DownloadItem) {
        cancel(item)
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(item.id.uuidString))
        items.removeAll { $0.id == item.id }; persist()
    }
}
