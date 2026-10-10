// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

final class AboutHomeHandler: InternalSchemeResponse {
    static let path = "about/home"

    // Return a blank page, the webview delegate will look at the current URL and load the home panel based on that
    func response(forRequest request: URLRequest, useOldErrorPage: Bool = false) -> (URLResponse, Data)? {
        guard let url = request.url else { return nil }
        let response = InternalSchemeHandler.response(forUrl: url)
        // Blank page with a color matching the background of the panels which
        // is displayed for a split-second until the panel shows.
        let html = """
            <!DOCTYPE html>
            <html>
              <body></body>
            </html>
        """
        guard let data = html.data(using: .utf8) else { return nil }
        return (response, data)
    }
}

final class AboutLicenseHandler: InternalSchemeResponse {
    static let path = "about/license"

    func response(forRequest request: URLRequest, useOldErrorPage: Bool = false) -> (URLResponse, Data)? {
        guard let url = request.url else { return nil }
        let response = InternalSchemeHandler.response(forUrl: url)
        guard let path = Bundle.main.path(forResource: "Licenses", ofType: "html"),
              let html = try? String(contentsOfFile: path, encoding: .utf8),
              let data = html.data(using: .utf8)
        else { return nil }

        return (response, data)
    }
}

final class AsterSupportPageHandler: InternalSchemeResponse {
    private let path: String
    private let resourceName: String

    init(path: String, resourceName: String) {
        self.path = path
        self.resourceName = resourceName
    }

    func response(forRequest request: URLRequest, useOldErrorPage: Bool = false) -> (URLResponse, Data)? {
        guard let url = request.url,
              url.scheme == InternalURL.scheme,
              url.host == "local",
              url.path == "/\(path)",
              request.isPrivileged,
              let resource = Bundle.main.url(forResource: resourceName,
                                             withExtension: "html",
                                             subdirectory: "AsterSupport"),
              let data = try? Data(contentsOf: resource)
        else { return nil }

        return (InternalSchemeHandler.response(forUrl: url), data)
    }
}
