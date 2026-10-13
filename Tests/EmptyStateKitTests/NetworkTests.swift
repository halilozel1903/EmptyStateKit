import Network
import Testing
@testable import EmptyStateKit

@Suite("Network status")
struct NetworkStatusTests {
    @Test("a satisfied path is online through its interface")
    func satisfied() {
        let status = NetworkStatus(pathStatus: .satisfied, interfaceType: .wifi)
        #expect(status.connectivity == .online)
        #expect(status.interface == .wifi)
        #expect(status.isOnline)
        #expect(!status.isOffline)
    }

    @Test("an unsatisfied path is offline with no interface")
    func unsatisfied() {
        let status = NetworkStatus(pathStatus: .unsatisfied, interfaceType: .cellular)
        #expect(status.connectivity == .offline)
        #expect(status.interface == nil)
        #expect(status.isOffline)
        #expect(!status.isOnline)
    }

    @Test("a path that requires a connection counts as online")
    func requiresConnection() {
        let status = NetworkStatus(pathStatus: .requiresConnection, interfaceType: nil)
        #expect(status.connectivity == .requiresConnection)
        #expect(status.isOnline)
        #expect(!status.isOffline)
    }

    @Test("cost and Low Data Mode are kept")
    func flags() {
        let status = NetworkStatus(pathStatus: .satisfied, interfaceType: .cellular, isExpensive: true, isConstrained: true)
        #expect(status.interface == .cellular)
        #expect(status.isExpensive)
        #expect(status.isConstrained)
    }

    @Test("interface types map one to one")
    func interfaces() {
        #expect(NetworkStatus.Interface(NWInterface.InterfaceType.wifi) == .wifi)
        #expect(NetworkStatus.Interface(NWInterface.InterfaceType.cellular) == .cellular)
        #expect(NetworkStatus.Interface(NWInterface.InterfaceType.wiredEthernet) == .wiredEthernet)
        #expect(NetworkStatus.Interface(NWInterface.InterfaceType.loopback) == .loopback)
        #expect(NetworkStatus.Interface(NWInterface.InterfaceType.other) == .other)
    }

    @Test("unknown is neither online nor offline")
    func unknown() {
        #expect(!NetworkStatus.unknown.isOnline)
        #expect(!NetworkStatus.unknown.isOffline)
        #expect(NetworkStatus.online.isOnline)
        #expect(NetworkStatus.offline.isOffline)
    }
}

@MainActor
@Suite("Network monitor")
struct NetworkMonitorTests {
    @Test("a simulated monitor reports what it is told")
    func simulated() {
        let monitor = NetworkMonitor.simulated(.offline)
        #expect(monitor.isSimulated)
        #expect(monitor.isOffline)
        monitor.simulate(.online)
        #expect(monitor.isOnline)
        #expect(monitor.status == .online)
    }

    @Test("a live monitor is not simulated")
    func live() {
        let monitor = NetworkMonitor()
        #expect(!monitor.isSimulated)
    }
}

@Suite("Offline banner")
struct OfflineBannerModelTests {
    @Test("hidden while online, shown while offline, back online after reconnecting")
    func lifecycle() {
        var model = OfflineBannerModel()
        model.update(.unknown)
        #expect(model.phase == .hidden)
        model.update(.online)
        #expect(model.phase == .hidden)
        #expect(!model.hasBeenOffline)

        model.update(.offline)
        #expect(model.phase == .offline)
        #expect(model.hasBeenOffline)

        model.update(.online)
        #expect(model.phase == .backOnline)
        model.dismissBackOnline()
        #expect(model.phase == .hidden)
    }

    @Test("dismissing does not hide the offline banner")
    func dismissKeepsOffline() {
        var model = OfflineBannerModel()
        model.update(.offline)
        model.dismissBackOnline()
        #expect(model.phase == .offline)
    }

    @Test("an unknown report while offline keeps the banner")
    func unknownWhileOffline() {
        var model = OfflineBannerModel()
        model.update(.offline)
        model.update(.unknown)
        #expect(model.phase == .offline)
    }

    @Test("going offline again while back online shows the offline banner")
    func flapping() {
        var model = OfflineBannerModel()
        model.update(.offline)
        model.update(.requiresConnection)
        #expect(model.phase == .backOnline)
        model.update(.offline)
        #expect(model.phase == .offline)
    }
}
