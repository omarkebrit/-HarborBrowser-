import SwiftUI
import UIKit

@main
struct HarborBrowserApp: App {
    @StateObject private var browser = BrowserModel()
    @Environment(\.scenePhase) private var scenePhase
    var body: some Scene {
        WindowGroup {
            BrowserScreen()
                .environmentObject(browser)
                .background(WindowPrivacyCover(visible: scenePhase != .active))
                .task { await browser.prepare() }
        }
    }
}

// A window-level cover also obscures presented sheets in app-switcher snapshots.
// It does not close tabs or alter either website data store.
@MainActor
private struct WindowPrivacyCover: UIViewRepresentable {
    let visible: Bool

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PrivacyWindowAnchor {
        let anchor = PrivacyWindowAnchor()
        anchor.isUserInteractionEnabled = false
        let coordinator = context.coordinator
        anchor.onWindowChange = { [weak coordinator] window in coordinator?.attach(to: window) }
        coordinator.setVisible(visible)
        return anchor
    }

    func updateUIView(_ anchor: PrivacyWindowAnchor, context: Context) {
        context.coordinator.attach(to: anchor.window)
        context.coordinator.setVisible(visible)
    }

    static func dismantleUIView(_ anchor: PrivacyWindowAnchor, coordinator: Coordinator) {
        anchor.onWindowChange = nil
        coordinator.attach(to: nil)
    }

    @MainActor
    final class Coordinator {
        private weak var window: UIWindow?
        private var visible = false
        private let cover = Coordinator.makeCover()
        private var observers: [NSObjectProtocol] = []

        init() {
            // Cover synchronously when this scene resigns activity, before its
            // snapshot is taken; scenePhase remains the source of steady state.
            observers.append(NotificationCenter.default.addObserver(forName: UIScene.willDeactivateNotification, object: nil, queue: .main) { [weak self] notification in
                MainActor.assumeIsolated {
                    guard let self, let scene = notification.object as? UIWindowScene, scene === self.window?.windowScene else { return }
                    self.setVisible(true)
                }
            })
            observers.append(NotificationCenter.default.addObserver(forName: UIScene.didActivateNotification, object: nil, queue: .main) { [weak self] notification in
                MainActor.assumeIsolated {
                    guard let self, let scene = notification.object as? UIWindowScene, scene === self.window?.windowScene else { return }
                    self.setVisible(false)
                }
            })
        }

        deinit {
            observers.forEach(NotificationCenter.default.removeObserver)
        }

        func attach(to newWindow: UIWindow?) {
            guard window !== newWindow else { return }
            cover.removeFromSuperview()
            window = newWindow
            refresh()
        }

        func setVisible(_ newValue: Bool) {
            visible = newValue
            refresh()
        }

        private func refresh() {
            guard visible, let window else { cover.removeFromSuperview(); return }
            cover.frame = window.bounds
            if cover.superview !== window { window.addSubview(cover) }
            window.bringSubviewToFront(cover)
        }

        private static func makeCover() -> UIView {
            let cover = UIView()
            cover.backgroundColor = UIColor(red: 0.04, green: 0.09, blue: 0.12, alpha: 1)
            cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            cover.accessibilityIdentifier = "PrivacyCover"
            cover.isAccessibilityElement = true
            cover.accessibilityLabel = "Harbor. Browsing content hidden."
            cover.accessibilityViewIsModal = true

            let icon = UIImageView(image: UIImage(systemName: "sailboat.fill"))
            icon.tintColor = .systemTeal
            icon.contentMode = .scaleAspectFit
            icon.translatesAutoresizingMaskIntoConstraints = false
            icon.isAccessibilityElement = false
            NSLayoutConstraint.activate([icon.heightAnchor.constraint(equalToConstant: 64), icon.widthAnchor.constraint(equalToConstant: 64)])

            let title = UILabel()
            title.text = "Harbor"
            title.textColor = .white
            title.font = .preferredFont(forTextStyle: .largeTitle)
            title.adjustsFontForContentSizeCategory = true
            title.textAlignment = .center

            let detail = UILabel()
            detail.text = "Browsing content hidden"
            detail.textColor = UIColor.white.withAlphaComponent(0.65)
            detail.font = .preferredFont(forTextStyle: .subheadline)
            detail.adjustsFontForContentSizeCategory = true
            detail.textAlignment = .center
            detail.numberOfLines = 0

            let stack = UIStackView(arrangedSubviews: [icon, title, detail])
            stack.axis = .vertical
            stack.alignment = .center
            stack.spacing = 20
            stack.translatesAutoresizingMaskIntoConstraints = false
            cover.addSubview(stack)
            NSLayoutConstraint.activate([
                stack.centerXAnchor.constraint(equalTo: cover.centerXAnchor),
                stack.centerYAnchor.constraint(equalTo: cover.centerYAnchor),
                stack.leadingAnchor.constraint(greaterThanOrEqualTo: cover.leadingAnchor, constant: 24),
                stack.trailingAnchor.constraint(lessThanOrEqualTo: cover.trailingAnchor, constant: -24)
            ])
            return cover
        }
    }
}

private final class PrivacyWindowAnchor: UIView {
    var onWindowChange: ((UIWindow?) -> Void)?
    override func didMoveToWindow() {
        super.didMoveToWindow()
        onWindowChange?(window)
    }
}
