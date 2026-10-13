import EmptyStateKit
import SwiftUI

/// The example app's bundled demo content. None of it comes from a real service.
struct DemoRecipe: Identifiable, Hashable {
    let id: Int
    let name: String
    let minutes: Int
    let systemImage: String
    let tint: Color

    static let all: [DemoRecipe] = [
        DemoRecipe(id: 1, name: "Lemon Herb Pasta", minutes: 20, systemImage: "fork.knife", tint: .yellow),
        DemoRecipe(id: 2, name: "Tomato Basil Soup", minutes: 35, systemImage: "cup.and.saucer.fill", tint: .red),
        DemoRecipe(id: 3, name: "Green Garden Salad", minutes: 10, systemImage: "leaf.fill", tint: .green),
        DemoRecipe(id: 4, name: "Roasted Vegetables", minutes: 45, systemImage: "flame.fill", tint: .orange),
        DemoRecipe(id: 5, name: "Berry Overnight Oats", minutes: 5, systemImage: "takeoutbag.and.cup.and.straw.fill", tint: .purple),
        DemoRecipe(id: 6, name: "Mushroom Risotto", minutes: 40, systemImage: "frying.pan.fill", tint: .brown),
        DemoRecipe(id: 7, name: "Chickpea Curry", minutes: 30, systemImage: "fork.knife.circle.fill", tint: .orange),
        DemoRecipe(id: 8, name: "Banana Pancakes", minutes: 15, systemImage: "birthday.cake.fill", tint: .yellow),
        DemoRecipe(id: 9, name: "Citrus Iced Tea", minutes: 5, systemImage: "wineglass.fill", tint: .teal),
    ]

    static func matching(_ query: String) -> [DemoRecipe] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return all }
        return all.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }
}

struct DemoArticle: Identifiable, Hashable {
    let id: Int
    let title: String
    let summary: String

    static let all: [DemoArticle] = [
        DemoArticle(id: 1, title: "Demo article one", summary: "Placeholder text for the example feed."),
        DemoArticle(id: 2, title: "Demo article two", summary: "Shown when the simulated network is online."),
        DemoArticle(id: 3, title: "Demo article three", summary: "Pull to refresh reloads the demo feed."),
    ]
}

struct DemoMessage: Identifiable, Hashable {
    let id = UUID()
    let subject: String
}

/// The error the demo photo service fails with.
struct DemoServiceError: LocalizedError {
    var errorDescription: String? { "The photo server didn't respond in time." }
    var recoverySuggestion: String? { "Your photos are safe; try again in a moment." }
}

/// The example app's sample content for each preset, with demo actions.
@MainActor
enum DemoContent {
    static func content(for preset: EmptyStatePreset) -> EmptyStateContent {
        switch preset {
        case .noResults:
            .noResults(for: "dragon fruit tacos")
                .primaryAction("Clear Search", systemImage: "xmark.circle") {}
        case .emptyInbox:
            .emptyInbox
                .primaryAction("Compose", systemImage: "square.and.pencil") {}
        case .offline:
            .offline
                .retryAction { try await failAfterDelay(URLError(.notConnectedToInternet)) }
        case .error:
            .error(DemoServiceError())
                .retryAction { try await failAfterDelay(DemoServiceError()) }
                .secondaryAction("Report") {}
        case .noPermission:
            .noPermission(to: "your photos")
                .action(.openSettings())
                .secondaryAction("Not Now") {}
        case .firstRun:
            .firstRun(title: "Welcome to Notes", message: "Write your first note to get started.")
                .primaryAction("New Note", systemImage: "plus") {}
                .secondaryAction("Import") {}
        }
    }

    /// The demo retries wait a moment and fail again, to show the retrying and failed states.
    private static func failAfterDelay(_ error: any Error) async throws {
        try await Task.sleep(for: .seconds(1.2))
        throw error
    }
}
