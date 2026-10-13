import Foundation
import SwiftUI

/// Scenes used by CI to capture the README screenshots. Launch with `-screenshot <scene>`; normal launches are
/// unaffected.
///
/// EmptyStateKit is a UI library, so the scenes show its views over the example app's bundled demo content: demo
/// recipes, a demo feed and a demo photo service. The offline scene uses a simulated ``NetworkMonitor`` (the CI
/// machine is online), and the error scene's demo service fails on purpose. Each scene writes its ready marker only
/// once the state it shows is on screen.
enum ScreenshotScene: String {
    /// iPhone: a recipe search that matches nothing.
    case noResults = "no-results"
    /// iPhone: the feed with the offline banner and the offline state, in dark mode.
    case offline
    /// iPhone: the photo library's error state, with the second retry running.
    case error
    /// Mac: every preset as a card.
    case gallery

    /// The scene this launch asked for. A `mac-` or `iphone-` prefix is accepted too.
    static var current: ScreenshotScene? {
        guard var name = argument(after: "-screenshot") else { return nil }
        for prefix in ["mac-", "iphone-"] where name.hasPrefix(prefix) {
            name.removeFirst(prefix.count)
        }
        return ScreenshotScene(rawValue: name)
    }

    /// Where the ready marker goes: `-screenshot-marker <path>` (the Mac script passes one), or
    /// `tmp/screenshot-ready` in the app's container (what the iPhone script watches).
    static var markerURL: URL {
        if let path = argument(after: "-screenshot-marker") {
            return URL(fileURLWithPath: path)
        }
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("screenshot-ready")
    }

    /// Mac only: `-render-screenshot <file>` asks the app to draw its window into a PNG itself once ready, the
    /// fallback when `screencapture` cannot capture the window.
    static var renderPath: String? {
        argument(after: "-render-screenshot")
    }

    private static func argument(after flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else {
            return nil
        }
        return arguments[index + 1]
    }

    /// The iPhone tab the scene opens.
    var tab: DemoTab {
        switch self {
        case .noResults: .recipes
        case .offline: .feed
        case .error: .photos
        case .gallery: .gallery
        }
    }

    /// The scene's appearance: the iPhone scenes show light and dark mode, the Mac gallery dark mode.
    var colorScheme: ColorScheme {
        switch self {
        case .noResults, .error: .light
        case .offline, .gallery: .dark
        }
    }
}

extension View {
    /// Tells the screenshot scripts that the scene is on screen by writing the ready marker once `isReady` is true
    /// and the transitions have settled.
    func signalsScreenshotReady(_ scene: ScreenshotScene?, when isReady: Bool) -> some View {
        task(id: isReady) {
            guard let scene, isReady else { return }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            do {
                try scene.rawValue.write(to: ScreenshotScene.markerURL, atomically: true, encoding: .utf8)
                print("Screenshot scene \(scene.rawValue) is ready")
            } catch {
                print("Could not write the screenshot marker: \(error)")
                return
            }
            #if os(macOS)
            await MainActor.run {
                ScreenshotWindowCoordinator.shared.sceneIsReady()
            }
            #endif
        }
    }
}
