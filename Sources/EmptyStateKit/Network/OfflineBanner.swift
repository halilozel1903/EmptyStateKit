import SwiftUI

/// A small capsule that says the device is offline, or that it is back online.
public struct OfflineBanner: View {
    public enum Kind: Sendable {
        case offline
        case backOnline
    }

    private let kind: Kind
    private let offlineTitle: String
    private let offlineDetail: String?
    private let backOnlineTitle: String

    public init(
        _ kind: Kind,
        offlineTitle: String = "You're offline",
        offlineDetail: String? = "Showing saved content",
        backOnlineTitle: String = "Back online"
    ) {
        self.kind = kind
        self.offlineTitle = offlineTitle
        self.offlineDetail = offlineDetail
        self.backOnlineTitle = backOnlineTitle
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: kind == .offline ? "wifi.slash" : "wifi")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 28, height: 28)
                .background(Circle().fill(kind == .offline ? Color.orange : Color.green))
            VStack(alignment: .leading, spacing: 1) {
                Text(kind == .offline ? offlineTitle : backOnlineTitle)
                    .font(.subheadline.weight(.semibold))
                if kind == .offline, let offlineDetail {
                    Text(offlineDetail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 8)
        .padding(.trailing, 16)
        .padding(.vertical, 7)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.updatesFrequently)
    }
}

extension View {
    /// Shows an ``OfflineBanner`` at the top (or bottom) of this view while the monitor reports no connection,
    /// and a "Back online" banner for `backOnlineDuration` when the connection returns. VoiceOver announces both.
    public func offlineBanner(
        _ monitor: NetworkMonitor,
        edge: VerticalEdge = .top,
        backOnlineDuration: Duration = .seconds(2.5)
    ) -> some View {
        modifier(OfflineBannerModifier(monitor: monitor, edge: edge, backOnlineDuration: backOnlineDuration))
    }

    /// Runs `action` each time the monitor goes from offline back to online, such as to reload what failed.
    public func onNetworkReconnect(
        _ monitor: NetworkMonitor,
        perform action: @escaping @MainActor () async -> Void
    ) -> some View {
        modifier(ReconnectModifier(monitor: monitor, action: action))
    }
}

private struct OfflineBannerModifier: ViewModifier {
    let monitor: NetworkMonitor
    let edge: VerticalEdge
    let backOnlineDuration: Duration

    @State private var model = OfflineBannerModel()

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: edge, spacing: 0) {
                ZStack {
                    switch model.phase {
                    case .offline:
                        OfflineBanner(.offline)
                            .transition(.move(edge: edge == .top ? .top : .bottom).combined(with: .opacity))
                    case .backOnline:
                        OfflineBanner(.backOnline)
                            .transition(.move(edge: edge == .top ? .top : .bottom).combined(with: .opacity))
                    case .hidden:
                        EmptyView()
                    }
                }
                .padding(.vertical, model.phase == .hidden ? 0 : 8)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
            }
            .animation(.spring(duration: 0.4), value: model.phase)
            .onChange(of: monitor.status.connectivity, initial: true) { _, connectivity in
                let before = model.phase
                model.update(connectivity)
                announce(from: before, to: model.phase)
            }
            .task(id: model.phase) {
                guard model.phase == .backOnline else { return }
                try? await Task.sleep(for: backOnlineDuration)
                guard !Task.isCancelled else { return }
                model.dismissBackOnline()
            }
    }

    private func announce(from before: OfflineBannerModel.Phase, to after: OfflineBannerModel.Phase) {
        guard before != after else { return }
        switch after {
        case .offline: AccessibilityNotification.Announcement("You're offline").post()
        case .backOnline: AccessibilityNotification.Announcement("Back online").post()
        case .hidden: break
        }
    }
}

private struct ReconnectModifier: ViewModifier {
    let monitor: NetworkMonitor
    let action: @MainActor () async -> Void

    @State private var wasOffline = false

    func body(content: Content) -> some View {
        content
            .onChange(of: monitor.status.connectivity, initial: true) { _, connectivity in
                switch connectivity {
                case .offline:
                    wasOffline = true
                case .online, .requiresConnection:
                    guard wasOffline else { return }
                    wasOffline = false
                    Task { await action() }
                case .unknown:
                    break
                }
            }
    }
}
