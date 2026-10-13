import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// A button shown by an empty state: a primary action, a secondary one, or a retry.
///
/// The handler is asynchronous and may throw. While it runs, the button shows a spinner and ignores further taps.
/// A retry action runs through the view's ``RetryController``, which also counts attempts and keeps the message of
/// the last failure on screen.
public struct EmptyStateAction: Identifiable, Sendable {
    /// What the action is for. It decides how prominent the button is and where it sits.
    public enum Kind: Int, Sendable, CaseIterable, Comparable {
        /// Tries the failed work again. Shown first, as a prominent button, with a retrying state.
        case retry
        /// The main way forward, such as Compose or Clear Search. Shown as a prominent button.
        case primary
        /// An alternative, such as Not Now or Browse All. Shown as a plain button.
        case secondary

        public static func < (lhs: Kind, rhs: Kind) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    /// The handler type: runs on the main actor, may suspend and may throw. Being main-actor isolated, it can use
    /// your view's state directly, like a `Button` action.
    public typealias Handler = @MainActor () async throws -> Void

    /// Identifies the action within its empty state: its kind and title.
    public var id: String { "\(kind.rawValue)-\(title)" }
    public var kind: Kind
    public var title: String
    /// An SF Symbol shown before the title, or nil for text only.
    public var systemImage: String?
    /// The title shown while a retry runs. Only used by `.retry` actions.
    public var progressTitle: String
    public var perform: Handler

    public init(
        _ kind: Kind,
        title: String,
        systemImage: String? = nil,
        progressTitle: String = "Retrying…",
        perform: @escaping Handler
    ) {
        self.kind = kind
        self.title = title
        self.systemImage = systemImage
        self.progressTitle = progressTitle
        self.perform = perform
    }

    /// A prominent button for the main way forward.
    public static func primary(
        _ title: String,
        systemImage: String? = nil,
        perform: @escaping Handler
    ) -> EmptyStateAction {
        EmptyStateAction(.primary, title: title, systemImage: systemImage, perform: perform)
    }

    /// A plain button for an alternative.
    public static func secondary(
        _ title: String,
        systemImage: String? = nil,
        perform: @escaping Handler
    ) -> EmptyStateAction {
        EmptyStateAction(.secondary, title: title, systemImage: systemImage, perform: perform)
    }

    /// A retry button. While `perform` runs it shows a spinner and `progressTitle`; when it throws, the error's
    /// message appears under the button and the button can be tapped again.
    public static func retry(
        _ title: String = "Try Again",
        systemImage: String? = "arrow.clockwise",
        progressTitle: String = "Retrying…",
        perform: @escaping Handler
    ) -> EmptyStateAction {
        EmptyStateAction(.retry, title: title, systemImage: systemImage, progressTitle: progressTitle, perform: perform)
    }

    /// The URL of this app's page in Settings on iPhone, or of Privacy & Security in System Settings on the Mac.
    @MainActor
    public static var settingsURL: URL? {
        #if canImport(UIKit) && !os(watchOS)
        URL(string: UIApplication.openSettingsURLString)
        #else
        URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")
        #endif
    }

    /// A primary button that opens Settings, for permission states.
    public static func openSettings(_ title: String = "Open Settings") -> EmptyStateAction {
        .primary(title, systemImage: "gear") {
            guard let url = settingsURL else { return }
            #if canImport(UIKit) && !os(watchOS)
            _ = await UIApplication.shared.open(url)
            #elseif canImport(AppKit)
            _ = NSWorkspace.shared.open(url)
            #endif
        }
    }
}
