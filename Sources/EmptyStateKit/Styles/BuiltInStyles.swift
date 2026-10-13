import SwiftUI

/// A large illustration centred above the title, message and buttons. See ``EmptyStateStyle/illustrated``.
public struct IllustratedEmptyStateStyle: EmptyStateStyle {
    /// The illustration's size in points at the default text size.
    public var illustrationSize: CGFloat

    public init(illustrationSize: CGFloat = 170) {
        self.illustrationSize = illustrationSize
    }

    @MainActor
    public func makeBody(configuration: Configuration) -> some View {
        IllustratedLayout(configuration: configuration, illustrationSize: illustrationSize)
    }
}

/// A small illustration beside the text and buttons. See ``EmptyStateStyle/compact``.
public struct CompactEmptyStateStyle: EmptyStateStyle {
    public var illustrationSize: CGFloat

    public init(illustrationSize: CGFloat = 60) {
        self.illustrationSize = illustrationSize
    }

    @MainActor
    public func makeBody(configuration: Configuration) -> some View {
        CompactLayout(configuration: configuration, illustrationSize: illustrationSize)
    }
}

/// The illustrated layout on a rounded card. See ``EmptyStateStyle/card``.
public struct CardEmptyStateStyle: EmptyStateStyle {
    public var illustrationSize: CGFloat
    public var cornerRadius: CGFloat

    public init(illustrationSize: CGFloat = 104, cornerRadius: CGFloat = 22) {
        self.illustrationSize = illustrationSize
        self.cornerRadius = cornerRadius
    }

    @MainActor
    public func makeBody(configuration: Configuration) -> some View {
        CardLayout(configuration: configuration, illustrationSize: illustrationSize, cornerRadius: cornerRadius)
    }
}

/// The system's `ContentUnavailableView`. See ``EmptyStateStyle/contentUnavailable``.
public struct ContentUnavailableEmptyStateStyle: EmptyStateStyle {
    /// Draw the illustration instead of showing the SF Symbol.
    public var usesIllustration: Bool

    public init(usesIllustration: Bool = false) {
        self.usesIllustration = usesIllustration
    }

    @MainActor
    public func makeBody(configuration: Configuration) -> some View {
        ContentUnavailableView {
            if usesIllustration, configuration.content.illustration != EmptyStateIllustration.none {
                Label {
                    Text(configuration.content.title)
                } icon: {
                    IllustrationIcon(configuration: configuration)
                }
            } else {
                Label(configuration.content.title, systemImage: configuration.content.systemImage)
            }
        } description: {
            if let message = configuration.message {
                message
            }
        } actions: {
            if configuration.hasActions {
                configuration.actionButtons(layout: .vertical)
            }
        }
    }
}

/// The drawn illustration sized for the icon slot of `ContentUnavailableView`, growing with Dynamic Type.
private struct IllustrationIcon: View {
    let configuration: EmptyStateStyleConfiguration
    @ScaledMetric(relativeTo: .largeTitle) private var size: CGFloat = 96

    var body: some View {
        configuration.illustration
            .frame(width: min(size, 150), height: min(size, 150))
    }
}

// MARK: - Layouts

/// Grows the illustration with Dynamic Type up to a limit, and shrinks it at the accessibility sizes so the text
/// has room.
private struct ScaledIllustrationSize: DynamicProperty {
    let base: CGFloat
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 1
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(base: CGFloat) {
        self.base = base
    }

    var value: CGFloat {
        dynamicTypeSize.isAccessibilitySize ? base * 0.7 : base * min(scale, 1.25)
    }
}

private struct IllustratedLayout: View {
    let configuration: EmptyStateStyleConfiguration
    private var size: ScaledIllustrationSize

    init(configuration: EmptyStateStyleConfiguration, illustrationSize: CGFloat) {
        self.configuration = configuration
        size = ScaledIllustrationSize(base: illustrationSize)
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 22) {
                    if configuration.content.illustration != EmptyStateIllustration.none {
                        configuration.illustration
                            .frame(width: size.value, height: size.value)
                    }
                    VStack(spacing: 8) {
                        configuration.title
                            .font(.title2.bold())
                        if let message = configuration.message {
                            message
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
                    .fixedSize(horizontal: false, vertical: true)
                    if configuration.hasActions {
                        configuration.actions
                            .controlSize(.large)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity, minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

private struct CompactLayout: View {
    let configuration: EmptyStateStyleConfiguration
    private var size: ScaledIllustrationSize
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(configuration: EmptyStateStyleConfiguration, illustrationSize: CGFloat) {
        self.configuration = configuration
        size = ScaledIllustrationSize(base: illustrationSize)
    }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 16))
        layout {
            if configuration.content.illustration != EmptyStateIllustration.none {
                configuration.illustration
                    .frame(width: size.value, height: size.value)
            }
            VStack(alignment: .leading, spacing: 4) {
                configuration.title
                    .font(.headline)
                if let message = configuration.message {
                    message
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if configuration.hasActions {
                    configuration.actionButtons(layout: .horizontal)
                        .controlSize(.small)
                        .padding(.top, 6)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
}

private struct CardLayout: View {
    let configuration: EmptyStateStyleConfiguration
    let cornerRadius: CGFloat
    private var size: ScaledIllustrationSize

    init(configuration: EmptyStateStyleConfiguration, illustrationSize: CGFloat, cornerRadius: CGFloat) {
        self.configuration = configuration
        self.cornerRadius = cornerRadius
        size = ScaledIllustrationSize(base: illustrationSize)
    }

    var body: some View {
        VStack(spacing: 14) {
            if configuration.content.illustration != EmptyStateIllustration.none {
                configuration.illustration
                    .frame(width: size.value, height: size.value)
            }
            VStack(spacing: 6) {
                configuration.title
                    .font(.title3.bold())
                if let message = configuration.message {
                    message
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            if configuration.hasActions {
                configuration.actions
                    .padding(.top, 4)
            }
        }
        .padding(24)
        // Fills a fixed-size grid cell; takes its ideal height in a scroll view.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.primary.opacity(0.045))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.09), lineWidth: 1)
                }
        }
    }
}
