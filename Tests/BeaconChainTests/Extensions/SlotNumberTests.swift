import XCTest
@testable import BeaconChain

final class SlotNumberTests: XCTestCase {

    func testToEpoch() {
        XCTAssertEqual(SlotNumber(128).toEpoch(), 2)
    }
}