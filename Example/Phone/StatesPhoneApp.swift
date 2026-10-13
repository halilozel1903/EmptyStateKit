import EmptyStateKit
import SwiftUI

/// The EmptyStateKit demo for iPhone: a recipe search, an inbox, a feed that reacts to the network, a photo
/// library whose demo server fails, and a gallery of every preset.
@main
struct StatesPhoneApp: App {
    var body: some Scene {
        WindowGroup {
            PhoneRootView(scene: ScreenshotScene.current)
        }
    }
}

struct PhoneRootView: View {
    let scene: ScreenshotScene?

    @State private var tab: DemoTab
    @State private var search: RecipeSearchModel
    @State private var inbox = InboxModel()
    @State private var feed: FeedModel
    @State private var photos: PhotosModel

    init(scene: ScreenshotScene?) {
        self.scene = scene
        _tab = State(initialValue: scene?.tab ?? .recipes)
        _search = State(initialValue: RecipeSearchModel(query: scene == .noResults ? "dragon fruit tacos" : ""))
        // The offline scene simulates a lost connection; normal launches watch the real network.
        let network = scene == .offline ? NetworkMonitor.simulated(.offline) : NetworkMonitor()
        _feed = State(initialValue: FeedModel(network: network))
        let photos = PhotosModel(failures: scene == .error ? 3 : 2)
        photos.hangsOnLastFailure = scene == .error
        _photos = State(initialValue: photos)
    }

    var body: some View {
        TabView(selection: $tab) {
            RecipesScreen(model: search, scene: scene)
                .tabItem { Label("Recipes", systemImage: "fork.knife") }
                .tag(DemoTab.recipes)
            InboxScreen(model: inbox)
                .tabItem { Label("Inbox", systemImage: "tray") }
                .tag(DemoTab.inbox)
            FeedScreen(model: feed, scene: scene)
                .tabItem { Label("Feed", systemImage: "newspaper") }
                .tag(DemoTab.feed)
            PhotosScreen(model: photos, scene: scene)
                .tabItem { Label("Photos", systemImage: "photo.on.rectangle") }
                .tag(DemoTab.photos)
            PhoneGalleryScreen()
                .tabItem { Label("Gallery", systemImage: "square.grid.2x2") }
                .tag(DemoTab.gallery)
        }
        .preferredColorScheme(scene?.colorScheme)
    }
}

/// Inline titles with a visible bar: iOS 26 can drop a large title while a scroll view settles under it.
private struct InlineNavigation: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension View {
    func inlineNavigation(_ title: String) -> some View {
        modifier(InlineNavigation(title: title))
    }
}

// MARK: - Recipes

struct RecipesScreen: View {
    @Bindable var model: RecipeSearchModel
    let scene: ScreenshotScene?

    var body: some View {
        NavigationStack {
            List(model.results) { recipe in
                HStack(spacing: 14) {
                    Image(systemName: recipe.systemImage)
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(recipe.tint.gradient, in: .rect(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(recipe.name)
                            .font(.headline)
                        Text("\(recipe.minutes) min")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .emptyState(
                when: model.results.isEmpty,
                .noResults(for: model.query)
                    .primaryAction("Clear Search", systemImage: "xmark.circle") { [model] in model.query = "" }
                    .secondaryAction("Browse All Recipes") { [model] in model.query = "" }
            )
            .inlineNavigation("Recipes")
            .searchable(
                text: $model.query,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search demo recipes"
            )
        }
        .signalsScreenshotReady(scene == .noResults ? scene : nil, when: model.results.isEmpty)
    }
}

// MARK: - Inbox

struct InboxScreen: View {
    @Bindable var model: InboxModel

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.messages) { message in
                    Label(message.subject, systemImage: "envelope")
                }
                .onDelete { model.messages.remove(atOffsets: $0) }
            }
            .emptyState(
                for: model.messages,
                .emptyInbox
                    .primaryAction("Compose", systemImage: "square.and.pencil") { [model] in model.compose() }
            )
            .inlineNavigation("Inbox")
            .toolbar {
                Button("Compose", systemImage: "square.and.pencil") { model.compose() }
            }
        }
    }
}

// MARK: - Feed

struct FeedScreen: View {
    let model: FeedModel
    let scene: ScreenshotScene?

    var body: some View {
        NavigationStack {
            List(model.articles) { article in
                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title)
                        .font(.headline)
                    Text(article.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
            .refreshable { await model.loadIgnoringErrors() }
            .emptyState(when: model.articles.isEmpty) {
                if let error = model.error {
                    EmptyStateView(
                        .failure(error).retryAction { [model] in try await model.load() },
                        retry: model.retry
                    )
                } else {
                    ProgressView()
                }
            }
            .offlineBanner(model.network)
            .inlineNavigation("Feed")
        }
        .onNetworkReconnect(model.network) {
            await model.retry.retry { try await model.load() }
        }
        .task { await model.loadIgnoringErrors() }
        .signalsScreenshotReady(scene == .offline ? scene : nil, when: model.error != nil && model.network.isOffline)
    }
}

// MARK: - Photos

struct PhotosScreen: View {
    let model: PhotosModel
    let scene: ScreenshotScene?

    private let columns = [GridItem(.adaptive(minimum: 90), spacing: 4)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(model.tiles, id: \.self) { tile in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hue: Double(tile) / 24, saturation: 0.45, brightness: 0.9).gradient)
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
                .padding(4)
            }
            .emptyState(when: model.tiles.isEmpty) {
                if let error = model.error {
                    EmptyStateView(
                        .error(error)
                            .retryAction { [model] in try await model.load() }
                            .secondaryAction("Report a Problem") {},
                        retry: model.retry
                    )
                } else {
                    ProgressView()
                }
            }
            .inlineNavigation("Photos")
        }
        .task {
            await model.loadIgnoringErrors()
            if scene == .error {
                // As if the retry button were tapped twice: the first retry fails, the second keeps running.
                await model.retry.retry { try await model.load() }
                await model.retry.retry { try await model.load() }
            }
        }
        .signalsScreenshotReady(scene == .error ? scene : nil, when: model.retry.phase == .retrying(attempt: 2))
    }
}

// MARK: - Gallery

struct PhoneGalleryScreen: View {
    @State private var style = GalleryStyle.card

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Picker("Style", selection: $style) {
                        ForEach(GalleryStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    ForEach(EmptyStatePreset.allCases) { preset in
                        EmptyStateView(DemoContent.content(for: preset))
                            .frame(height: style.cellHeight)
                    }
                }
                .padding()
            }
            .galleryStyle(style)
            .inlineNavigation("Gallery")
        }
    }
}
