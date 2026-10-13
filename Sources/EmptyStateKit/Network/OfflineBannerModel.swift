import Foundation

/// Decides what the offline banner shows as the connection changes: nothing while online, an offline banner while
/// offline, and a short "back online" banner after the connection returns.
public struct OfflineBannerModel: Equatable, Sendable {
    public enum Phase: Equatable, Sendable {
        case hidden
        case offline
        case backOnline
    }

    public private(set) var phase: Phase = .hidden
    /// Whether the device has been offline since the model was made. "Back online" only shows after that.
    public private(set) var hasBeenOffline = false

    public init() {}

    /// Feeds in the latest connectivity.
    public mutating func update(_ connectivity: NetworkStatus.Connectivity) {
        switch connectivity {
        case .offline:
            phase = .offline
            hasBeenOffline = true
        case .online, .requiresConnection:
            phase = phase == .offline ? .backOnline : (phase == .backOnline ? .backOnline : .hidden)
        case .unknown:
            break
        }
    }

    /// Hides the "back online" banner, once it has been on screen long enough. An offline banner stays.
    public mutating func dismissBackOnline() {
        if phase == .backOnline {
            phase = .hidden
        }
    }
}
