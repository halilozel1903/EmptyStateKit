import SwiftUI

/// A picture for an empty state. The built-in ones are vector drawings made from SwiftUI shapes, so they scale to
/// any size, take the state's tint and adapt to dark mode; no image assets are bundled.
public enum EmptyStateIllustration: Sendable, Hashable {
    /// A magnifying glass over a page: no results.
    case magnifier
    /// An empty tray with the outline of a letter above it: an empty inbox or list.
    case tray
    /// A cloud with a slash through it: offline.
    case cloudOffline
    /// A rounded warning triangle: an error.
    case warning
    /// A padlock: no permission.
    case lock
    /// Three sparkles: a first run.
    case sparkles
    /// Any SF Symbol, drawn on the same backdrop as the built-in illustrations.
    case systemImage(String)
    /// No illustration.
    case none

    /// Every drawn illustration, for galleries and pickers.
    public static let drawn: [EmptyStateIllustration] = [.magnifier, .tray, .cloudOffline, .warning, .lock, .sparkles]
}
