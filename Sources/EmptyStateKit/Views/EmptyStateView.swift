import SwiftUI

/// An empty, error, offline or first-run state: an illustration, a title, a message and buttons, laid out by the
/// current ``EmptyStateStyle``.
///
/// ```swift
/// EmptyStateView(.noResults(for: query).primaryAction("Clear Search") { query = "" })
///
/// EmptyStateView(.failure(error).retryAction { try await model.reload() })
///
/// EmptyStateView(.emptyInbox)
///     .emptyStateStyle(.compact)
/// ```
public struct EmptyStateView: View {
    private let content: EmptyStateContent
    private let externalRetry: RetryController?

    @State private var ownRetry = RetryController()
    @Environment(\.emptyStateStyle) private var style

    /// - Parameters:
    ///   - content: What to show.
    ///   - retry: The retry state to show and drive. Pass your own to start retries from elsewhere, or to keep the
    ///     attempt count when the view is recreated; by default the view keeps its own.
    public init(_ content: EmptyStateContent, retry: RetryController? = nil) {
        self.content = content
        externalRetry = retry
    }

    /// A custom state.
    public init(
        _ title: String,
        message: String? = nil,
        illustration: EmptyStateIllustration = .none,
        tint: Color? = nil,
        actions: [EmptyStateAction] = [],
        retry: RetryController? = nil
    ) {
        self.init(
            EmptyStateContent(title: title, message: message, illustration: illustration, tint: tint, actions: actions),
            retry: retry
        )
    }

    public var body: some View {
        style.makeBody(configuration: EmptyStateStyleConfiguration(content: content, retry: externalRetry ?? ownRetry))
            .accessibilityElement(children: .contain)
    }
}

extension ContentUnavailableView where Label == SwiftUI.Label<Text, Image>, Description == Text?, Actions == EmptyStateActionsView {
    /// The system's `ContentUnavailableView` for an empty state: its SF Symbol, title, message and buttons, with
    /// the buttons' running and retrying states.
    ///
    /// ```swift
    /// ContentUnavailableView(.noResults(for: query))
    /// ```
    ///
    /// Pass a ``RetryController`` you keep in `@State` when the content has a retry action, so the retry state
    /// survives the view being recreated.
    @MainActor
    public init(_ content: EmptyStateContent, retry: RetryController? = nil) {
        let retry = retry ?? RetryController()
        self.init {
            SwiftUI.Label(content.title, systemImage: content.systemImage)
        } description: {
            content.message.map { Text($0) }
        } actions: {
            EmptyStateActionsView(content: content, retry: retry, layout: .vertical)
        }
    }
}
