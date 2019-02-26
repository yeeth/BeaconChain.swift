import XCTest
@testable import BeaconChain

final class ForkTests: XCTestCase {

    func testVersion() {
        let fork = Fork(previousVersion: 10, currentVersion: 20, epoch: 1)
        XCTAssertEqual(10, fork.version(epoch: 0))
        XCTAssertEqual(20, fork.version(epoch: 2))
    }
}
