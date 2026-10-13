import Foundation
import SwiftUI
import Testing
@testable import EmptyStateKit

struct OutOfStock: LocalizedError {
    var errorDescription: String? { "This item is out of stock." }
    var recoverySuggestion: String? { "Check back tomorrow." }
}

struct DescriptionOnly: LocalizedError {
    var errorDescription: String? { "The server didn't respond in time." }
}

struct PlainError: Error {}

@Suite("Presets and content")
struct ContentTests {
    @Test("every preset has text, a symbol and its own illustration")
    func presetsAreComplete() {
        for preset in EmptyStatePreset.allCases {
            #expect(!preset.title.isEmpty)
            #expect(!preset.message.isEmpty)
            #expect(!preset.systemImage.isEmpty)
            #expect(!preset.name.isEmpty)
            #expect(EmptyStateIllustration.drawn.contains(preset.illustration))
        }
        let illustrations = Set(EmptyStatePreset.allCases.map(\.illustration))
        #expect(illustrations.count == EmptyStatePreset.allCases.count)
    }

    @Test("content made from a preset copies it and has no actions")
    func contentFromPreset() {
        let content = EmptyStateContent(.offline)
        #expect(content.title == "You're Offline")
        #expect(content.message == EmptyStatePreset.offline.message)
        #expect(content.illustration == .cloudOffline)
        #expect(content.systemImage == "wifi.slash")
        #expect(content.preset == .offline)
        #expect(content.actions.isEmpty)
        #expect(content.tint != nil)
    }

    @Test("no results names a trimmed query and ignores a blank one")
    func noResultsQuery() {
        #expect(EmptyStateContent.noResults(for: "  dragon fruit tacos \n").title == "No Results for “dragon fruit tacos”")
        #expect(EmptyStateContent.noResults(for: "   ").title == "No Results")
        #expect(EmptyStateContent.noResults().title == "No Results")
        #expect(EmptyStateContent.noResults(for: "x").illustration == .magnifier)
    }

    @Test("an error state shows a localized error's description and suggestion")
    func errorMessages() {
        #expect(EmptyStateContent.error(OutOfStock()).message == "This item is out of stock. Check back tomorrow.")
        #expect(EmptyStateContent.error(DescriptionOnly()).message == "The server didn't respond in time.")
        #expect(EmptyStateContent.error(PlainError()).message == EmptyStatePreset.error.message)
        #expect(EmptyStateContent.error().message == EmptyStatePreset.error.message)
        #expect(EmptyStateContent.error(PlainError()).title == "Something Went Wrong")
    }

    @Test("no permission and first run take custom text")
    func customText() {
        #expect(EmptyStateContent.noPermission(to: "your photos").message == "Allow access to your photos in Settings to see them here.")
        #expect(EmptyStateContent.noPermission().message == EmptyStatePreset.noPermission.message)
        let firstRun = EmptyStateContent.firstRun(title: "No Notes Yet", message: "Tap + to write one.")
        #expect(firstRun.title == "No Notes Yet")
        #expect(firstRun.message == "Tap + to write one.")
        #expect(firstRun.illustration == .sparkles)
    }

    @Test("builders return changed copies and leave the original alone")
    func builders() {
        let original = EmptyStateContent.emptyInbox
        let changed = original
            .title("Nothing Here")
            .message(nil)
            .illustration(.systemImage("envelope"))
            .systemImage("envelope")
            .tint(.red)
            .primaryAction("Compose") {}
        #expect(original.title == "No Messages")
        #expect(original.actions.isEmpty)
        #expect(changed.title == "Nothing Here")
        #expect(changed.message == nil)
        #expect(changed.illustration == .systemImage("envelope"))
        #expect(changed.systemImage == "envelope")
        #expect(changed.actions.count == 1)
        #expect(changed.preset == .emptyInbox)
    }

    @Test("a custom state starts without a preset")
    func customContent() {
        let content = EmptyStateContent(title: "No Downloads", message: "Saved episodes appear here.", illustration: .tray)
        #expect(content.preset == nil)
        #expect(content.tint == nil)
        #expect(content.systemImage == "questionmark.circle")
    }
}

@Suite("Actions")
struct ActionTests {
    @Test("actions are shown retry first, then primary, then secondary, each in the order added")
    func ordering() {
        let content = EmptyStateContent.error()
            .secondaryAction("Report") {}
            .primaryAction("Go Home") {}
            .retryAction {}
            .primaryAction("Contact Us") {}
        #expect(content.actions.map(\.title) == ["Report", "Go Home", "Try Again", "Contact Us"])
        #expect(content.orderedActions.map(\.title) == ["Try Again", "Go Home", "Contact Us", "Report"])
        #expect(content.orderedActions.map(\.kind) == [.retry, .primary, .primary, .secondary])
        #expect(content.firstRetryAction?.title == "Try Again")
    }

    @Test("action factories set kind, symbol and progress title")
    func factories() {
        let retry = EmptyStateAction.retry {}
        #expect(retry.kind == .retry)
        #expect(retry.systemImage == "arrow.clockwise")
        #expect(retry.progressTitle == "Retrying…")
        let custom = EmptyStateAction.retry("Reconnect", systemImage: nil, progressTitle: "Reconnecting…") {}
        #expect(custom.title == "Reconnect")
        #expect(custom.systemImage == nil)
        #expect(custom.progressTitle == "Reconnecting…")
        #expect(EmptyStateAction.primary("Compose", systemImage: "square.and.pencil") {}.kind == .primary)
        #expect(EmptyStateAction.secondary("Not Now") {}.kind == .secondary)
        #expect(EmptyStateAction.openSettings().kind == .primary)
        #expect(EmptyStateAction.openSettings().title == "Open Settings")
    }

    @Test("ids differ by kind and title")
    func identifiers() {
        let primary = EmptyStateAction.primary("Retry") {}
        let retry = EmptyStateAction.retry("Retry") {}
        #expect(primary.id != retry.id)
        #expect(EmptyStateContent.emptyInbox.firstRetryAction == nil)
    }

    @Test("kinds sort retry, primary, secondary")
    func kindOrder() {
        #expect(EmptyStateAction.Kind.allCases.sorted() == [.retry, .primary, .secondary])
    }
}
