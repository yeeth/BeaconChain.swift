import XCTest
@testable import BeaconChain

final class IntTests: XCTestCase {

    func testIsPowerOfTwo() {
        XCTAssertTrue(4.isPowerOfTwo())
        XCTAssertFalse(3.isPowerOfTwo())
    }
}
