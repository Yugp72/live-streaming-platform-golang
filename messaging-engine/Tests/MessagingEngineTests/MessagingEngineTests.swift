import XCTest
@testable import MessagingEngine

final class MessagingEngineTests: XCTestCase {
    func testExample() {
        // Basic test to ensure the module compiles
        let message = StandardMessage(
            payload: "test".data(using: .utf8)!,
            priority: .normal
        )
        XCTAssertNotNil(message)
    }
}

