import SwiftUI

@main
struct HarborBrowserApp: App {
    @StateObject private var browser = BrowserModel()
    var body: some Scene {
        WindowGroup { BrowserScreen().environmentObject(browser).task { await browser.prepare() } }
    }
}
