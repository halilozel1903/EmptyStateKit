import SwiftUI

extension View {
    /// Shows an empty state over this view while `isEmpty` is true, and hides this view meanwhile (also from
    /// VoiceOver). Navigation titles, toolbars and the search field of this view stay in place.
    ///
    /// ```swift
    /// List(results) { RecipeRow(recipe: $0) }
    ///     .emptyState(when: results.isEmpty, .noResults(for: query))
    /// ```
    public func emptyState(
        when isEmpty: Bool,
        _ content: @autoclosure () -> EmptyStateContent,
        retry: RetryController? = nil
    ) -> some View {
        modifier(EmptyStateOverlay(isEmpty: isEmpty, placeholder: isEmpty ? EmptyStateView(content(), retry: retry) : nil))
    }

    /// Shows your own view over this view while `isEmpty` is true.
    public func emptyState<Placeholder: View>(
        when isEmpty: Bool,
        @ViewBuilder placeholder: () -> Placeholder
    ) -> some View {
        modifier(EmptyStateOverlay(isEmpty: isEmpty, placeholder: isEmpty ? placeholder() : nil))
    }

    /// Shows an empty state over this view while `collection` is empty.
    public func emptyState<C: Collection>(
        for collection: C,
        _ content: @autoclosure () -> EmptyStateContent,
        retry: RetryController? = nil
    ) -> some View {
        emptyState(when: collection.isEmpty, content(), retry: retry)
    }
}

struct EmptyStateOverlay<Placeholder: View>: ViewModifier {
    let isEmpty: Bool
    let placeholder: Placeholder?

    func body(content: Content) -> some View {
        content
            .opacity(isEmpty ? 0 : 1)
            .allowsHitTesting(!isEmpty)
            .accessibilityHidden(isEmpty)
            .overlay {
                if isEmpty, let placeholder {
                    placeholder
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isEmpty)
    }
}
