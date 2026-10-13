import EmptyStateKit
import SwiftUI

/// The EmptyStateKit demo for the Mac: every preset in a grid, in the style picked in the toolbar, with a switch
/// that simulates going offline to show the banner.
@main
struct StatesMacApp: App {
    var body: some Scene {
        WindowGroup("Empty States") {
            MacGalleryView(scene: ScreenshotScene.current)
                .modifier(MacWindowSize(isScreenshot: ScreenshotScene.current != nil))
        }
        .defaultSize(width: MacWindowSize.screenshotSize.width, height: MacWindowSize.screenshotSize.height)
        .windowResizability(ScreenshotScene.current == nil ? .contentMinSize : .contentSize)
    }
}

/// A fixed size for screenshots, so every capture has the same frame; a minimum size otherwise.
struct MacWindowSize: ViewModifier {
    static let screenshotSize = CGSize(width: 1180, height: 760)
    let isScreenshot: Bool

    func body(content: Content) -> some View {
        if isScreenshot {
            content
                .frame(width: Self.screenshotSize.width, height: Self.screenshotSize.height)
                .preferredColorScheme(.dark)
                .background(ScreenshotWindow())
        } else {
            content
                .frame(minWidth: 760, minHeight: 520)
        }
    }
}

struct MacGalleryView: View {
    let scene: ScreenshotScene?

    @State private var style = GalleryStyle.card
    @State private var simulatesOffline = false
    @State private var liveNetwork: NetworkMonitor
    @State private var simulatedNetwork = NetworkMonitor.simulated(.online)

    private let columns = [
        GridItem(.flexible(), spacing: 20, alignment: .top),
        GridItem(.flexible(), spacing: 20, alignment: .top),
        GridItem(.flexible(), spacing: 20, alignment: .top),
    ]

    init(scene: ScreenshotScene?) {
        self.scene = scene
        // Screenshots never show the banner, whatever the CI machine's network does.
        _liveNetwork = State(initialValue: scene == nil ? NetworkMonitor() : NetworkMonitor.simulated(.online))
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(EmptyStatePreset.allCases) { preset in
                    EmptyStateView(DemoContent.content(for: preset))
                        .frame(height: style.cellHeight ?? (style == .card ? 320 : nil))
                }
            }
            .padding(24)
        }
        .galleryStyle(style)
        .offlineBanner(simulatesOffline ? simulatedNetwork : liveNetwork)
        .navigationTitle("Empty States")
        .navigationSubtitle("\(EmptyStatePreset.allCases.count) presets · \(style.title) style")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("Style", selection: $style) {
                    ForEach(GalleryStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
            ToolbarItem {
                Toggle(isOn: $simulatesOffline) {
                    Label("Simulate Offline", systemImage: "wifi.slash")
                }
                .help("Simulate losing the connection to show the offline banner")
            }
        }
        .onChange(of: simulatesOffline) { _, offline in
            simulatedNetwork.simulate(offline ? .offline : .online)
        }
        .signalsScreenshotReady(scene, when: true)
    }
}
