import SwiftUI

/// The built-in empty states. Each one has an illustration, a tint, an SF Symbol for `ContentUnavailableView`, and
/// default English text you can replace.
public enum EmptyStatePreset: String, Sendable, CaseIterable, Identifiable {
    /// A search or filter matched nothing.
    case noResults
    /// A list that has nothing in it yet, such as an inbox.
    case emptyInbox
    /// The device has no network connection.
    case offline
    /// Loading failed.
    case error
    /// The app may not show this content until the person grants access.
    case noPermission
    /// Nothing has been created yet: the first launch.
    case firstRun

    public var id: String { rawValue }

    /// The vector illustration drawn for this state.
    public var illustration: EmptyStateIllustration {
        switch self {
        case .noResults: .magnifier
        case .emptyInbox: .tray
        case .offline: .cloudOffline
        case .error: .warning
        case .noPermission: .lock
        case .firstRun: .sparkles
        }
    }

    /// The SF Symbol used by the `ContentUnavailableView` style and by ``EmptyStateIllustration/systemImage(_:)``.
    public var systemImage: String {
        switch self {
        case .noResults: "magnifyingglass"
        case .emptyInbox: "tray"
        case .offline: "wifi.slash"
        case .error: "exclamationmark.triangle"
        case .noPermission: "lock"
        case .firstRun: "sparkles"
        }
    }

    /// The accent of the illustration and of the prominent buttons.
    public var tint: Color {
        switch self {
        case .noResults: .blue
        case .emptyInbox: .teal
        case .offline: .indigo
        case .error: .orange
        case .noPermission: .purple
        case .firstRun: .pink
        }
    }

    /// The default title.
    public var title: String {
        switch self {
        case .noResults: "No Results"
        case .emptyInbox: "No Messages"
        case .offline: "You're Offline"
        case .error: "Something Went Wrong"
        case .noPermission: "Access Needed"
        case .firstRun: "Welcome"
        }
    }

    /// The default message.
    public var message: String {
        switch self {
        case .noResults: "Check the spelling or try a different search."
        case .emptyInbox: "New messages will show up here."
        case .offline: "Check your Wi-Fi or cellular connection. This page refreshes when you're back online."
        case .error: "This content couldn't be loaded. Please try again."
        case .noPermission: "Allow access in Settings to see this content here."
        case .firstRun: "There's nothing here yet. Create your first item to get started."
        }
    }

    /// A short name for galleries and pickers.
    public var name: String {
        switch self {
        case .noResults: "No results"
        case .emptyInbox: "Empty inbox"
        case .offline: "Offline"
        case .error: "Error"
        case .noPermission: "No permission"
        case .firstRun: "First run"
        }
    }
}
