import Foundation
import Network
import Observation

/// Watches the network with `NWPathMonitor` and publishes a ``NetworkStatus`` on the main actor.
///
/// Keep one for the app (in `@State` at the root, or in your model) and hand it to ``SwiftUICore/View/offlineBanner(_:edge:backOnlineDuration:)``
/// and ``SwiftUICore/View/onNetworkReconnect(_:perform:)``:
///
/// ```swift
/// @State private var network = NetworkMonitor()
///
/// ContentView()
///     .offlineBanner(network)
/// ```
///
/// For previews, tests and screenshots, ``simulated(_:)`` makes a monitor that never looks at the real network;
/// change its status with ``simulate(_:)``.
@MainActor
@Observable
public final class NetworkMonitor {
    /// The latest status. ``NetworkStatus/unknown`` until the monitor first reports.
    public private(set) var status: NetworkStatus

    /// Whether this monitor reports a simulated status instead of the real network.
    public let isSimulated: Bool

    private let box: PathMonitorBox?

    /// Starts watching the network at once.
    /// - Parameter interfaceType: Watch only this kind of interface, such as `.wifi`. Nil watches every interface.
    public init(requiring interfaceType: NWInterface.InterfaceType? = nil) {
        status = .unknown
        isSimulated = false
        let box = PathMonitorBox(interfaceType: interfaceType)
        self.box = box
        box.start { [weak self] status in
            Task { @MainActor [weak self] in
                self?.status = status
            }
        }
    }

    private init(simulated status: NetworkStatus) {
        self.status = status
        isSimulated = true
        box = nil
    }

    /// A monitor that reports `status` and ignores the real network, for previews, tests and screenshots.
    public static func simulated(_ status: NetworkStatus = .online) -> NetworkMonitor {
        NetworkMonitor(simulated: status)
    }

    /// Changes a simulated monitor's status. Does nothing on a monitor that watches the real network.
    public func simulate(_ status: NetworkStatus) {
        guard isSimulated else { return }
        self.status = status
    }

    /// Whether the device is known to be offline.
    public var isOffline: Bool {
        status.isOffline
    }

    /// Whether the device is known to be online.
    public var isOnline: Bool {
        status.isOnline
    }
}

/// Owns the `NWPathMonitor` and its queue outside the main actor. The update handler is made here, in a
/// nonisolated context, so it is not treated as main-actor code when the monitor calls it on its queue.
private final class PathMonitorBox: @unchecked Sendable {
    // Only touched in init, start and deinit; NWPathMonitor is safe to cancel from any thread.
    private let monitor: NWPathMonitor
    private let queue = DispatchQueue(label: "io.github.halilozel1903.EmptyStateKit.NetworkMonitor", qos: .utility)

    init(interfaceType: NWInterface.InterfaceType?) {
        monitor = interfaceType.map { NWPathMonitor(requiredInterfaceType: $0) } ?? NWPathMonitor()
    }

    func start(onUpdate: @escaping @Sendable (NetworkStatus) -> Void) {
        monitor.pathUpdateHandler = { path in
            onUpdate(NetworkStatus(path))
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
