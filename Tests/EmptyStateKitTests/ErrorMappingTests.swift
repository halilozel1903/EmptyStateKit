import Foundation
import Testing
@testable import EmptyStateKit

@Suite("Mapping errors to states")
struct ErrorMappingTests {
    @Test("connection errors are offline", arguments: [
        NSURLErrorNotConnectedToInternet,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorDataNotAllowed,
        NSURLErrorInternationalRoamingOff,
    ])
    func offlineCodes(rawCode: Int) {
        let code = URLError.Code(rawValue: rawCode)
        #expect(EmptyStateContent.isConnectivityError(URLError(code)))
        #expect(EmptyStateContent.failure(URLError(code)).preset == .offline)
    }

    @Test("other URL errors are errors", arguments: [
        NSURLErrorTimedOut,
        NSURLErrorBadServerResponse,
        NSURLErrorCannotFindHost,
        NSURLErrorCancelled,
    ])
    func otherCodes(rawCode: Int) {
        let code = URLError.Code(rawValue: rawCode)
        #expect(!EmptyStateContent.isConnectivityError(URLError(code)))
        #expect(EmptyStateContent.failure(URLError(code)).preset == .error)
    }

    @Test("bridged and wrapped NSErrors are recognised")
    func nsErrors() {
        let bridged = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        #expect(EmptyStateContent.isConnectivityError(bridged))
        let wrapped = NSError(domain: "Feed", code: 7, userInfo: [NSUnderlyingErrorKey: bridged])
        #expect(EmptyStateContent.isConnectivityError(wrapped))
        #expect(!EmptyStateContent.isConnectivityError(NSError(domain: "Feed", code: 7)))
    }

    @Test("non-network errors become error states with their message")
    func otherErrors() {
        #expect(!EmptyStateContent.isConnectivityError(PlainError()))
        let content = EmptyStateContent.failure(DescriptionOnly())
        #expect(content.preset == .error)
        #expect(content.message == "The server didn't respond in time.")
    }

    @Test("failed retries get a short readable line")
    func retryFailureText() {
        #expect(ErrorText.retryFailure(for: URLError(.notConnectedToInternet)) == "You're still offline.")
        #expect(ErrorText.retryFailure(for: DescriptionOnly()) == "The server didn't respond in time.")
        #expect(ErrorText.retryFailure(for: PlainError()) == "That didn't work. Please try again.")
    }
}
