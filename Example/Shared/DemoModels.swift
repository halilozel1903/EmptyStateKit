import EmptyStateKit
import Foundation
import Observation

/// The tabs of the iPhone app.
enum DemoTab: Hashable {
    case recipes, inbox, feed, photos, gallery
}

@MainActor
@Observable
final class RecipeSearchModel {
    var query: String

    init(query: String = "") {
        self.query = query
    }

    var results: [DemoRecipe] {
        DemoRecipe.matching(query)
    }
}

@MainActor
@Observable
final class InboxModel {
    var messages: [DemoMessage] = []

    func compose() {
        messages.append(DemoMessage(subject: "Demo message \(messages.count + 1)"))
    }
}

/// A demo feed that loads only while the network monitor reports a connection.
@MainActor
@Observable
final class FeedModel {
    private(set) var articles: [DemoArticle] = []
    private(set) var error: (any Error)?
    private(set) var isLoading = false
    let network: NetworkMonitor
    let retry = RetryController()

    init(network: NetworkMonitor) {
        self.network = network
    }

    func load() async throws {
        isLoading = true
        defer { isLoading = false }
        try await Task.sleep(for: .milliseconds(600))
        guard !network.isOffline else {
            let offline = URLError(.notConnectedToInternet)
            error = offline
            throw offline
        }
        articles = DemoArticle.all
        error = nil
    }

    func loadIgnoringErrors() async {
        try? await load()
    }
}

/// A demo photo service that fails a set number of times before it works, to show the error and retrying states.
@MainActor
@Observable
final class PhotosModel {
    private(set) var tiles: [Int] = []
    private(set) var error: (any Error)?
    let retry = RetryController()
    private var failuresLeft: Int
    /// The screenshot scene keeps the second retry running so the retrying state stays on screen.
    var hangsOnLastFailure = false

    init(failures: Int = 2) {
        failuresLeft = failures
    }

    func load() async throws {
        try await Task.sleep(for: .milliseconds(800))
        if failuresLeft > 0 {
            failuresLeft -= 1
            if failuresLeft == 0, hangsOnLastFailure {
                try await Task.sleep(for: .seconds(3600))
            }
            let failure = DemoServiceError()
            error = failure
            throw failure
        }
        tiles = Array(0..<24)
        error = nil
    }

    func loadIgnoringErrors() async {
        try? await load()
    }
}
