import XCTest
@testable import BeaconChain

final class EpochNumberTests: XCTestCase {

    func testStartSlot() {
        XCTAssertEqual(EpochNumber(1).startSlot(), 64)
    }

    func testEntryExitEpoch() {
        XCTAssertEqual(EpochNumber(1).entryExitEpoch(), 6)
    }
}
