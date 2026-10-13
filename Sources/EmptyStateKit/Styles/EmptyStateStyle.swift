import SwiftUI

/// Decides how an ``EmptyStateView`` lays out its illustration, text and actions.
///
/// Pick a built-in style with ``SwiftUICore/View/emptyStateStyle(_:)``, or write your own: build the view from the
/// configuration's parts, so the actions keep their async and retrying states.
///
/// ```swift
/// struct BannerEmptyStateStyle: EmptyStateStyle {
///     @MainActor func makeBody(configuration: Configuration) -> some View {
///         HStack {
///             configuration.illustration.frame(width: 44, height: 44)
///             configuration.title.font(.headline)
///             Spacer()
///             configuration.actions.controlSize(.small)
///         }
///         .padding()
///     }
/// }
/// ```
public protocol EmptyStateStyle: Sendable {
    associatedtype Body: View

    /// The view for one empty state.
    @MainActor @ViewBuilder
    func makeBody(configuration: Configuration) -> Body

    typealias Configuration = EmptyStateStyleConfiguration
}

/// What a style gets to build an empty state from.
@MainActor
public struct EmptyStateStyleConfiguration {
    /// The title, message, illustration, tint and actions.
    public let content: EmptyStateContent
    /// The view's retry state.
    public let retry: RetryController

    public init(content: EmptyStateContent, retry: RetryController) {
        self.content = content
        self.retry = retry
    }

    /// The illustration in the content's tint. Size it with `frame(width:height:)`.
    public var illustration: EmptyStateIllustrationView {
        EmptyStateIllustrationView(content.illustration, tint: content.tint)
    }

    /// The title as text, marked as a header for VoiceOver.
    public var title: some View {
        Text(content.title)
            .accessibilityAddTraits(.isHeader)
    }

    /// The message as text, or nil.
    public var message: Text? {
        content.message.map { Text($0) }
    }

    /// The buttons, with their running and retrying states and the retry status line.
    public func actionButtons(layout: EmptyStateActionsView.Layout) -> EmptyStateActionsView {
        EmptyStateActionsView(content: content, retry: retry, layout: layout)
    }

    /// The buttons laid out automatically.
    public var actions: EmptyStateActionsView {
        actionButtons(layout: .automatic)
    }

    /// Whether the content has any actions.
    public var hasActions: Bool {
        !content.actions.isEmpty
    }
}

/// A type-erased ``EmptyStateStyle``, as stored in the environment.
public struct AnyEmptyStateStyle: EmptyStateStyle {
    private let make: @MainActor @Sendable (Configuration) -> AnyView

    public init<Style: EmptyStateStyle>(_ style: Style) {
        make = { configuration in
            AnyView(style.makeBody(configuration: configuration))
        }
    }

    @MainActor
    public func makeBody(configuration: Configuration) -> AnyView {
        make(configuration)
    }
}

private struct EmptyStateStyleKey: EnvironmentKey {
    static var defaultValue: AnyEmptyStateStyle {
        AnyEmptyStateStyle(IllustratedEmptyStateStyle())
    }
}

extension EnvironmentValues {
    /// The style empty state views use. Set it with ``SwiftUICore/View/emptyStateStyle(_:)``.
    public var emptyStateStyle: AnyEmptyStateStyle {
        get { self[EmptyStateStyleKey.self] }
        set { self[EmptyStateStyleKey.self] = newValue }
    }
}

extension View {
    /// Sets the style of the empty state views inside this view.
    public func emptyStateStyle<Style: EmptyStateStyle>(_ style: Style) -> some View {
        environment(\.emptyStateStyle, AnyEmptyStateStyle(style))
    }
}

// MARK: - Built-in styles

extension EmptyStateStyle where Self == IllustratedEmptyStateStyle {
    /// The default: a large illustration centred above the title, message and buttons. Fills the space it is
    /// given and scrolls when the text is too large to fit.
    public static var illustrated: IllustratedEmptyStateStyle { IllustratedEmptyStateStyle() }

    /// The default style, ``illustrated``.
    public static var automatic: IllustratedEmptyStateStyle { IllustratedEmptyStateStyle() }

    /// The illustrated style with an illustration of the given base size in points.
    public static func illustrated(size: CGFloat) -> IllustratedEmptyStateStyle {
        IllustratedEmptyStateStyle(illustrationSize: size)
    }
}

extension EmptyStateStyle where Self == CompactEmptyStateStyle {
    /// A small illustration beside the text and buttons, for list sections, sidebars and panels.
    public static var compact: CompactEmptyStateStyle { CompactEmptyStateStyle() }
}

extension EmptyStateStyle where Self == CardEmptyStateStyle {
    /// The illustrated layout on a rounded card, for grids and dashboards.
    public static var card: CardEmptyStateStyle { CardEmptyStateStyle() }
}

extension EmptyStateStyle where Self == ContentUnavailableEmptyStateStyle {
    /// The system's `ContentUnavailableView` with the content's SF Symbol, title, message and buttons.
    public static var contentUnavailable: ContentUnavailableEmptyStateStyle { ContentUnavailableEmptyStateStyle() }

    /// `ContentUnavailableView` with the drawn illustration in place of the SF Symbol.
    public static var illustratedContentUnavailable: ContentUnavailableEmptyStateStyle {
        ContentUnavailableEmptyStateStyle(usesIllustration: true)
    }
}
