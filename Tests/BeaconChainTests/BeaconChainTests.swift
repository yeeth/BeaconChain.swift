import XCTest
@testable import BeaconChain

final class BeaconChainTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(BeaconChain().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
