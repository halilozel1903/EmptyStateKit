import SwiftUI

/// The buttons of an empty state, with a spinner while an action runs, a retrying state for the retry action, and
/// a status line under them for the attempt count or the last failure.
///
/// The first action (in ``EmptyStateContent/orderedActions`` order) is prominent; other primary and retry actions
/// are bordered and secondary actions are plain. Errors thrown by primary and secondary actions are not shown;
/// handle them in the action. Errors thrown by a retry action appear under the buttons.
public struct EmptyStateActionsView: View {
    /// How the buttons are arranged.
    public enum Layout: Sendable {
        /// Side by side when they fit, otherwise stacked; always stacked at the accessibility text sizes.
        case automatic
        /// Stacked.
        case vertical
        /// Side by side, unless the text is at an accessibility size.
        case horizontal
    }

    private let content: EmptyStateContent
    private let layout: Layout
    private let retry: RetryController

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(content: EmptyStateContent, retry: RetryController, layout: Layout = .automatic) {
        self.content = content
        self.retry = retry
        self.layout = layout
    }

    public var body: some View {
        let actions = content.orderedActions
        if !actions.isEmpty {
            VStack(spacing: 12) {
                buttons(actions)
                if content.firstRetryAction != nil {
                    RetryStatusLine(retry: retry)
                }
            }
            .optionalTint(content.tint)
        }
    }

    @ViewBuilder
    private func buttons(_ actions: [EmptyStateAction]) -> some View {
        let stacked = VStack(spacing: 10) { row(actions, fillsWidth: true) }
            .fixedSize(horizontal: true, vertical: false)
        let sideBySide = HStack(spacing: 12) { row(actions, fillsWidth: false) }
        if dynamicTypeSize.isAccessibilitySize || layout == .vertical {
            stacked
        } else if layout == .horizontal {
            sideBySide
        } else {
            ViewThatFits(in: .horizontal) {
                sideBySide.fixedSize()
                stacked
            }
        }
    }

    private func row(_ actions: [EmptyStateAction], fillsWidth: Bool) -> some View {
        ForEach(Array(actions.enumerated()), id: \.element.id) { index, action in
            EmptyStateActionButton(
                action: action,
                emphasis: emphasis(of: action, at: index),
                fillsWidth: fillsWidth,
                retry: retry
            )
        }
    }

    private func emphasis(of action: EmptyStateAction, at index: Int) -> EmptyStateActionButton.Emphasis {
        if index == 0 { return .prominent }
        return action.kind == .secondary ? .plain : .bordered
    }
}

/// One action button.
struct EmptyStateActionButton: View {
    enum Emphasis {
        case prominent, bordered, plain
    }

    let action: EmptyStateAction
    let emphasis: Emphasis
    let fillsWidth: Bool
    let retry: RetryController

    @State private var isRunning = false

    private var isBusy: Bool {
        action.kind == .retry ? retry.isRetrying : isRunning
    }

    var body: some View {
        styled(
            Button(action: run) {
                label
                    .frame(maxWidth: fillsWidth ? .infinity : nil)
                    .frame(minWidth: emphasis == .plain ? nil : 120)
            }
        )
        .accessibilityValue(isBusy && action.kind == .retry ? Text(action.progressTitle) : Text(""))
        .animation(.snappy, value: isBusy)
    }

    @ViewBuilder
    private var label: some View {
        if isBusy {
            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .tint(emphasis == .prominent ? .white : nil)
                Text(action.kind == .retry ? action.progressTitle : action.title)
            }
        } else if let systemImage = action.systemImage {
            Label(action.title, systemImage: systemImage)
        } else {
            Text(action.title)
        }
    }

    @ViewBuilder
    private func styled(_ button: some View) -> some View {
        switch emphasis {
        case .prominent: button.buttonStyle(.borderedProminent)
        case .bordered: button.buttonStyle(.bordered)
        case .plain: button.buttonStyle(.borderless)
        }
    }

    private func run() {
        // Taps while busy are ignored rather than disabling the button, so the retrying state keeps its colour.
        guard !isBusy else { return }
        let action = action
        if action.kind == .retry {
            Task {
                await retry.retry {
                    try await action.perform()
                }
            }
        } else {
            isRunning = true
            Task {
                try? await action.perform()
                isRunning = false
            }
        }
    }
}

/// "Attempt 2" while a retry after the first runs, or the last failure's message.
private struct RetryStatusLine: View {
    let retry: RetryController

    var body: some View {
        Group {
            switch retry.phase {
            case .retrying(let attempt) where attempt > 1:
                Text("Attempt \(attempt)")
                    .foregroundStyle(.secondary)
            case .failed(_, let message):
                Label(message, systemImage: "exclamationmark.circle")
                    .foregroundStyle(.secondary)
            default:
                EmptyView()
            }
        }
        .font(.footnote)
        .multilineTextAlignment(.center)
        .onChange(of: retry.phase) { _, phase in
            if case .failed(_, let message) = phase {
                AccessibilityNotification.Announcement(message).post()
            }
        }
    }
}

extension View {
    /// Applies a tint only when there is one, keeping the environment's tint otherwise.
    @ViewBuilder
    func optionalTint(_ tint: Color?) -> some View {
        if let tint {
            self.tint(tint)
        } else {
            self
        }
    }
}
