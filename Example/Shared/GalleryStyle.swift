import EmptyStateKit
import SwiftUI

/// The styles the galleries switch between.
enum GalleryStyle: String, CaseIterable, Identifiable {
    case card
    case illustrated
    case compact
    case contentUnavailable

    var id: String { rawValue }

    var title: String {
        switch self {
        case .card: "Card"
        case .illustrated: "Illustrated"
        case .compact: "Compact"
        case .contentUnavailable: "System"
        }
    }

    /// A fixed height for the styles that fill the space they are given.
    var cellHeight: CGFloat? {
        switch self {
        case .card, .compact: nil
        case .illustrated: 440
        case .contentUnavailable: 400
        }
    }
}

extension View {
    @ViewBuilder
    func galleryStyle(_ style: GalleryStyle) -> some View {
        switch style {
        case .card: emptyStateStyle(.card)
        case .illustrated: emptyStateStyle(.illustrated)
        case .compact: emptyStateStyle(.compact)
        case .contentUnavailable: emptyStateStyle(.illustratedContentUnavailable)
        }
    }
}
