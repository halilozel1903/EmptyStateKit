import Foundation
import Testing
@testable import EmptyStateKit

/// Holds a retry open until the test lets it finish.
@MainActor
final class Gate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isOpen = false

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func open() {
        isOpen = true
        continuation?.resume()
        continuation = nil
    }
}

@MainActor
@Suite("Retry controller")
struct RetryControllerTests {
    @Test("a new controller is idle")
    func initialState() {
        let controller = RetryController()
        #expect(controller.phase == .idle)
        #expect(controller.attempts == 0)
        #expect(!controller.isRetrying)
        #expect(controller.failureMessage == nil)
    }

    @Test("a successful retry ends in succeeded")
    func success() async {
        let controller = RetryController(minimumDuration: .zero)
        var ran = false
        let succeeded = await controller.retry { ran = true }
        #expect(succeeded)
        #expect(ran)
        #expect(controller.phase == .succeeded(attempt: 1))
        #expect(controller.attempts == 1)
    }

    @Test("a failed retry keeps the error's message and counts attempts")
    func failure() async {
        let controller = RetryController(minimumDuration: .zero)
        let first = await controller.retry { throw DescriptionOnly() }
        #expect(!first)
        #expect(controller.phase == .failed(attempt: 1, message: "The server didn't respond in time."))
        #expect(controller.failureMessage == "The server didn't respond in time.")

        await controller.retry { throw URLError(.notConnectedToInternet) }
        #expect(controller.phase == .failed(attempt: 2, message: "You're still offline."))
        #expect(controller.attempts == 2)
    }

    @Test("a retry while another runs is ignored")
    func ignoresOverlappingRetries() async {
        let controller = RetryController(minimumDuration: .zero)
        let gate = Gate()
        let first = Task { await controller.retry { await gate.wait() } }
        while !controller.isRetrying {
            await Task.yield()
        }
        #expect(controller.phase == .retrying(attempt: 1))

        var secondRan = false
        let second = await controller.retry { secondRan = true }
        #expect(!second)
        #expect(!secondRan)
        #expect(controller.attempts == 1)

        gate.open()
        #expect(await first.value)
        #expect(controller.phase == .succeeded(attempt: 1))
    }

    @Test("the retrying phase shows the attempt number")
    func attemptNumber() async {
        let controller = RetryController(minimumDuration: .zero)
        await controller.retry { throw PlainError() }
        let gate = Gate()
        let second = Task { await controller.retry { await gate.wait() } }
        while !controller.isRetrying {
            await Task.yield()
        }
        #expect(controller.phase == .retrying(attempt: 2))
        gate.open()
        _ = await second.value
    }

    @Test("cancelling a retry puts the phase back")
    func cancellation() async {
        let controller = RetryController(minimumDuration: .zero)
        await controller.retry { throw PlainError() }
        let task = Task { await controller.retry { try await Task.sleep(for: .seconds(30)) } }
        while !controller.isRetrying {
            await Task.yield()
        }
        task.cancel()
        let succeeded = await task.value
        #expect(!succeeded)
        #expect(controller.phase == .failed(attempt: 1, message: "That didn't work. Please try again."))
        #expect(controller.attempts == 1)
    }

    @Test("a fast retry stays visible for the minimum duration")
    func minimumDuration() async {
        let controller = RetryController(minimumDuration: .milliseconds(200))
        let clock = ContinuousClock()
        let start = clock.now
        await controller.retry { throw PlainError() }
        #expect(clock.now - start >= .milliseconds(190))
    }

    @Test("reset forgets every attempt")
    func reset() async {
        let controller = RetryController(minimumDuration: .zero)
        await controller.retry { throw PlainError() }
        controller.reset()
        #expect(controller.phase == .idle)
        #expect(controller.attempts == 0)
    }
}
