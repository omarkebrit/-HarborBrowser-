import Foundation
import WebKit

// Keep media decisions in one place. WebKit remains responsible for decoding,
// streaming, user gestures, cookies, and the website's own player.
@MainActor
enum BrowserMedia {
    static func configure(_ configuration: WKWebViewConfiguration, preferences: BrowserPreferences) {
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.allowsAirPlayForMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = preferences.allowAutoplay ? [] : .all
        configuration.preferences.isElementFullscreenEnabled = true
        // False requires a user gesture; it still allows a tapped JavaScript
        // window.open(). NavigationType.other does not mean an unwanted popup.
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = !preferences.blockPopups
        configuration.defaultWebpagePreferences.preferredContentMode = .mobile

        let os = ProcessInfo.processInfo.operatingSystemVersion
        // WebKit supplies its device identity and Mobile token. Append only
        // the browser tokens; duplicating Mobile produces a malformed identity.
        configuration.applicationNameForUserAgent = "Version/\(os.majorVersion).\(os.minorVersion) Safari/604.1"
    }

    static func isPlayableResource(url: URL?, mimeType: String?) -> Bool {
        let mime = (mimeType ?? "").split(separator: ";", maxSplits: 1).first
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines).lowercased() } ?? ""
        if mime.hasPrefix("video/") || mime.hasPrefix("audio/") { return true }
        if ["application/vnd.apple.mpegurl", "application/x-mpegurl", "application/mpegurl"].contains(mime) { return true }
        // Some media CDNs send a generic binary MIME type for direct MP4/HLS
        // links. Let WebKit sniff supported formats instead of downloading them.
        guard ["", "application/octet-stream", "binary/octet-stream"].contains(mime) else { return false }
        return ["mp4", "m4v", "mov", "m3u8", "mp3", "m4a", "aac", "wav", "flac"].contains(url?.pathExtension.lowercased() ?? "")
    }

    static func responsePolicy(for response: URLResponse, canShowMIMEType: Bool, isForMainFrame: Bool) -> WKNavigationResponsePolicy {
        // Embedded documents and players belong to their parent page. A frame
        // response must never replace a working player with a file download.
        guard isForMainFrame else { return .allow }
        if let response = response as? HTTPURLResponse,
           response.value(forHTTPHeaderField: "Content-Disposition")?
            .trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix("attachment") == true {
            return .download
        }
        return canShowMIMEType || isPlayableResource(url: response.url, mimeType: response.mimeType) ? .allow : .download
    }
}
