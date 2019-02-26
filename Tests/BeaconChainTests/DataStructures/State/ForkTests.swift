import XCTest
@testable import BeaconChain

final class ForkTests: XCTestCase {

    func testVersion() {
        let fork = Fork(previousVersion: 10, currentVersion: 20, epoch: 1)
        XCTAssertEqual(10, fork.version(epoch: 0))
        XCTAssertEqual(20, fork.version(epoch: 2))
    }


    func testDomain() {
        let data = Fork(previousVersion: 2, currentVersion: 3, epoch: 10)
        let constant = 2**32

        XCTAssertEqual(
            data.domain(epoch: 9, type: .PROPOSAL),
            Epoch((2*constant)+2)
        )

        XCTAssertEqual(
            data.domain(epoch: 11, type: .EXIT),
            Epoch((3*constant)+3)
        )
    }
}
