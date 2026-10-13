import Foundation
import SwiftUI

/// Everything an empty state shows: an illustration, a title, a message, a tint and up to a few actions.
///
/// Start from a preset and adjust it with the builder methods:
///
/// ```swift
/// EmptyStateView(
///     .noResults(for: query)
///         .primaryAction("Clear Search") { query = "" }
/// )
/// ```
public struct EmptyStateContent: Sendable {
    public var illustration: EmptyStateIllustration
    public var title: String
    public var message: String?
    /// The SF Symbol used when the state is shown as a `ContentUnavailableView`.
    public var systemImage: String
    /// The accent of the illustration and the prominent buttons. Nil uses the environment's tint.
    public var tint: Color?
    /// The actions, in the order they were added. Views show them by ``EmptyStateAction/Kind`` (see ``orderedActions``).
    public var actions: [EmptyStateAction]
    /// The preset this content was made from, if any.
    public var preset: EmptyStatePreset?

    public init(
        title: String,
        message: String? = nil,
        illustration: EmptyStateIllustration = .none,
        systemImage: String = "questionmark.circle",
        tint: Color? = nil,
        actions: [EmptyStateAction] = []
    ) {
        self.title = title
        self.message = message
        self.illustration = illustration
        self.systemImage = systemImage
        self.tint = tint
        self.actions = actions
        preset = nil
    }

    /// The preset's illustration, text, symbol and tint, with no actions.
    public init(_ preset: EmptyStatePreset) {
        self.init(
            title: preset.title,
            message: preset.message,
            illustration: preset.illustration,
            systemImage: preset.systemImage,
            tint: preset.tint
        )
        self.preset = preset
    }

    /// Retry first, then primary, then secondary actions, each group in the order added.
    public var orderedActions: [EmptyStateAction] {
        actions.enumerated()
            .sorted { lhs, rhs in
                lhs.element.kind == rhs.element.kind ? lhs.offset < rhs.offset : lhs.element.kind < rhs.element.kind
            }
            .map(\.element)
    }

    /// The first retry action, if any.
    public var firstRetryAction: EmptyStateAction? {
        actions.first { $0.kind == .retry }
    }
}

// MARK: - Presets

extension EmptyStateContent {
    /// A search or filter matched nothing. With a query, the message names it.
    public static func noResults(for query: String? = nil) -> EmptyStateContent {
        var content = EmptyStateContent(.noResults)
        let trimmed = query?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !trimmed.isEmpty {
            content.title = "No Results for “\(trimmed)”"
        }
        return content
    }

    /// A list with nothing in it yet.
    public static var emptyInbox: EmptyStateContent {
        EmptyStateContent(.emptyInbox)
    }

    /// No network connection.
    public static var offline: EmptyStateContent {
        EmptyStateContent(.offline)
    }

    /// Loading failed. With an error, the message is its `errorDescription` (and recovery suggestion) when it is a
    /// `LocalizedError`; otherwise the preset's generic message is kept, so raw system errors don't reach people.
    public static func error(_ error: (any Error)? = nil) -> EmptyStateContent {
        var content = EmptyStateContent(.error)
        if let error, let message = ErrorText.message(for: error) {
            content.message = message
        }
        return content
    }

    /// The app needs permission. With a resource name such as "your photos", the message names it.
    public static func noPermission(to resource: String? = nil) -> EmptyStateContent {
        var content = EmptyStateContent(.noPermission)
        if let resource, !resource.isEmpty {
            content.message = "Allow access to \(resource) in Settings to see them here."
        }
        return content
    }

    /// Nothing created yet.
    public static func firstRun(title: String? = nil, message: String? = nil) -> EmptyStateContent {
        var content = EmptyStateContent(.firstRun)
        if let title { content.title = title }
        if let message { content.message = message }
        return content
    }

    /// The right state for a failure: ``offline`` for connection errors (see ``isConnectivityError(_:)``),
    /// ``error(_:)`` for anything else.
    public static func failure(_ error: any Error) -> EmptyStateContent {
        isConnectivityError(error) ? .offline : .error(error)
    }

    /// Whether an error means the device is offline, rather than that the server or the request failed.
    public static func isConnectivityError(_ error: any Error) -> Bool {
        if let urlError = error as? URLError {
            return ErrorText.offlineCodes.contains(urlError.code.rawValue)
        }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            return ErrorText.offlineCodes.contains(nsError.code)
        }
        if let underlying = nsError.userInfo[NSUnderlyingErrorKey] as? any Error {
            return isConnectivityError(underlying)
        }
        return false
    }
}

// MARK: - Builders

extension EmptyStateContent {
    /// Replaces the title.
    public func title(_ title: String) -> EmptyStateContent {
        var copy = self
        copy.title = title
        return copy
    }

    /// Replaces the message. Nil removes it.
    public func message(_ message: String?) -> EmptyStateContent {
        var copy = self
        copy.message = message
        return copy
    }

    /// Replaces the illustration.
    public func illustration(_ illustration: EmptyStateIllustration) -> EmptyStateContent {
        var copy = self
        copy.illustration = illustration
        return copy
    }

    /// Replaces the SF Symbol used by the `ContentUnavailableView` style.
    public func systemImage(_ systemImage: String) -> EmptyStateContent {
        var copy = self
        copy.systemImage = systemImage
        return copy
    }

    /// Replaces the tint. Nil uses the environment's tint.
    public func tint(_ tint: Color?) -> EmptyStateContent {
        var copy = self
        copy.tint = tint
        return copy
    }

    /// Adds an action.
    public func action(_ action: EmptyStateAction) -> EmptyStateContent {
        var copy = self
        copy.actions.append(action)
        return copy
    }

    /// Adds a prominent primary button.
    public func primaryAction(
        _ title: String,
        systemImage: String? = nil,
        perform: @escaping EmptyStateAction.Handler
    ) -> EmptyStateContent {
        action(.primary(title, systemImage: systemImage, perform: perform))
    }

    /// Adds a plain secondary button.
    public func secondaryAction(
        _ title: String,
        systemImage: String? = nil,
        perform: @escaping EmptyStateAction.Handler
    ) -> EmptyStateContent {
        action(.secondary(title, systemImage: systemImage, perform: perform))
    }

    /// Adds a retry button with a retrying state. If `perform` throws, the error's message shows under it.
    public func retryAction(
        _ title: String = "Try Again",
        progressTitle: String = "Retrying…",
        perform: @escaping EmptyStateAction.Handler
    ) -> EmptyStateContent {
        action(.retry(title, progressTitle: progressTitle, perform: perform))
    }
}

/// Turns errors into text people can read.
enum ErrorText {
    /// The raw `URLError.Code` values that mean there is no connection.
    static let offlineCodes: Set<Int> = [
        NSURLErrorNotConnectedToInternet,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorDataNotAllowed,
        NSURLErrorInternationalRoamingOff,
        NSURLErrorCallIsActive,
    ]

    /// The `errorDescription` and `recoverySuggestion` of a `LocalizedError`, or nil for other errors.
    static func message(for error: any Error) -> String? {
        guard let localized = error as? any LocalizedError,
              let description = localized.errorDescription?.trimmingCharacters(in: .whitespacesAndNewlines),
              !description.isEmpty
        else { return nil }
        guard let suggestion = localized.recoverySuggestion?.trimmingCharacters(in: .whitespacesAndNewlines),
              !suggestion.isEmpty
        else { return description }
        return "\(description) \(suggestion)"
    }

    /// A short line for a failed retry: the error's description, or a generic sentence.
    static func retryFailure(for error: any Error) -> String {
        if EmptyStateContent.isConnectivityError(error) {
            return "You're still offline."
        }
        return message(for: error) ?? "That didn't work. Please try again."
    }
}
