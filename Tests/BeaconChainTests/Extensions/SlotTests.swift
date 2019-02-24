import XCTest
@testable import BeaconChain

final class SlotTests: XCTestCase {

    func testToEpoch() {
        XCTAssertEqual(Slot(128).toEpoch(), 2)
    }
}