import Foundation
import Observation

/// Runs retries for an empty state and remembers how they went: whether one is running, how many attempts were
/// made and why the last one failed.
///
/// ``EmptyStateView`` makes one for itself. Create your own and pass it in to start a retry from elsewhere (pull to
/// refresh, a reconnect) and have the empty state show it:
///
/// ```swift
/// @State private var retry = RetryController()
///
/// EmptyStateView(.failure(error).retryAction { try await model.reload() }, retry: retry)
///     .onNetworkReconnect(monitor) { await retry.retry { try await model.reload() } }
/// ```
@MainActor
@Observable
public final class RetryController {
    /// Where the retries stand.
    public enum Phase: Equatable, Sendable {
        /// No retry yet, or ``RetryController/reset()`` was called.
        case idle
        /// A retry is running; `attempt` counts from 1.
        case retrying(attempt: Int)
        /// The last retry threw. `message` is readable text for the error.
        case failed(attempt: Int, message: String)
        /// The last retry finished without throwing.
        case succeeded(attempt: Int)
    }

    public private(set) var phase: Phase = .idle

    /// The number of retries started since the last reset.
    public private(set) var attempts = 0

    /// The shortest time a retry shows as running, so a fast failure doesn't flash the spinner for a frame.
    public var minimumDuration: Duration

    private let clock = ContinuousClock()

    public init(minimumDuration: Duration = .milliseconds(450)) {
        self.minimumDuration = minimumDuration
    }

    /// Whether a retry is running.
    public var isRetrying: Bool {
        if case .retrying = phase { return true }
        return false
    }

    /// The message of the last failed retry, or nil.
    public var failureMessage: String? {
        if case .failed(_, let message) = phase { return message }
        return nil
    }

    /// Runs `operation` as the next attempt. Returns whether it finished without throwing.
    ///
    /// A call while another retry is running returns false at once without running anything, so double taps and a
    /// reconnect during a retry don't start a second request. Cancellation is not a failure: the phase goes back to
    /// what it was before.
    @discardableResult
    public func retry(_ operation: @MainActor () async throws -> Void) async -> Bool {
        guard !isRetrying else { return false }
        let previous = phase
        attempts += 1
        let attempt = attempts
        phase = .retrying(attempt: attempt)
        let start = clock.now

        var thrown: (any Error)?
        do {
            try await operation()
        } catch {
            thrown = error
        }

        let elapsed = clock.now - start
        if elapsed < minimumDuration, !Task.isCancelled {
            try? await Task.sleep(for: minimumDuration - elapsed)
        }

        if let thrown {
            if thrown is CancellationError || Task.isCancelled {
                attempts -= 1
                phase = previous
            } else {
                phase = .failed(attempt: attempt, message: ErrorText.retryFailure(for: thrown))
            }
            return false
        }
        phase = .succeeded(attempt: attempt)
        return true
    }

    /// Forgets every attempt, back to ``Phase/idle``. A running retry keeps running, but its result is still
    /// recorded when it ends.
    public func reset() {
        attempts = 0
        phase = .idle
    }
}
