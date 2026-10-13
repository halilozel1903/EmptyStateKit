import Foundation
import Network

/// A snapshot of the device's network connection, as reported by `NWPathMonitor`.
public struct NetworkStatus: Equatable, Sendable {
    /// Whether there is a usable connection.
    public enum Connectivity: String, Equatable, Sendable {
        /// The monitor has not reported yet.
        case unknown
        /// There is a usable path to the network.
        case online
        /// There is no usable path.
        case offline
        /// A path may become usable once a connection is made, such as a VPN on demand or a cellular link that
        /// has to wake up. Treated as online by ``NetworkStatus/isOffline``.
        case requiresConnection
    }

    /// The kind of interface the connection goes through.
    public enum Interface: String, Equatable, Sendable {
        case wifi
        case cellular
        case wiredEthernet
        case loopback
        case other
    }

    public var connectivity: Connectivity
    /// The interface in use, or nil when offline or unknown.
    public var interface: Interface?
    /// Whether the connection is costly, such as cellular or a personal hotspot.
    public var isExpensive: Bool
    /// Whether Low Data Mode is on for the connection.
    public var isConstrained: Bool

    public init(
        connectivity: Connectivity,
        interface: Interface? = nil,
        isExpensive: Bool = false,
        isConstrained: Bool = false
    ) {
        self.connectivity = connectivity
        self.interface = interface
        self.isExpensive = isExpensive
        self.isConstrained = isConstrained
    }

    /// Before the first report.
    public static let unknown = NetworkStatus(connectivity: .unknown)
    /// Online over Wi-Fi.
    public static let online = NetworkStatus(connectivity: .online, interface: .wifi)
    /// Offline.
    public static let offline = NetworkStatus(connectivity: .offline)

    /// Whether the device is known to be offline. False while the status is unknown.
    public var isOffline: Bool {
        connectivity == .offline
    }

    /// Whether the device is known to be online.
    public var isOnline: Bool {
        connectivity == .online || connectivity == .requiresConnection
    }
}

extension NetworkStatus {
    /// Reads a path reported by `NWPathMonitor`.
    public init(_ path: NWPath) {
        let used = path.availableInterfaces.first { path.usesInterfaceType($0.type) }?.type
        self.init(
            pathStatus: path.status,
            interfaceType: used,
            isExpensive: path.isExpensive,
            isConstrained: path.isConstrained
        )
    }

    /// Builds a status from the parts of a path, so the mapping can be tested without a live `NWPath`.
    public init(
        pathStatus: NWPath.Status,
        interfaceType: NWInterface.InterfaceType?,
        isExpensive: Bool = false,
        isConstrained: Bool = false
    ) {
        let connectivity: Connectivity = switch pathStatus {
        case .satisfied: .online
        case .unsatisfied: .offline
        case .requiresConnection: .requiresConnection
        @unknown default: .unknown
        }
        self.init(
            connectivity: connectivity,
            interface: connectivity == .offline ? nil : interfaceType.map { Interface($0) },
            isExpensive: isExpensive,
            isConstrained: isConstrained
        )
    }
}

extension NetworkStatus.Interface {
    init(_ type: NWInterface.InterfaceType) {
        switch type {
        case .wifi: self = .wifi
        case .cellular: self = .cellular
        case .wiredEthernet: self = .wiredEthernet
        case .loopback: self = .loopback
        case .other: self = .other
        @unknown default: self = .other
        }
    }
}
