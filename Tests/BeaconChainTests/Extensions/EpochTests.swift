import XCTest
@testable import BeaconChain

final class EpochTests: XCTestCase {

    func testStartSlot() {
        XCTAssertEqual(Epoch(1).startSlot(), 64)
    }

    func testEntryExitEpoch() {
        XCTAssertEqual(Epoch(1).delayedActivationExitEpoch(), 6)
    }
}
