import XCTest
@testable import BeaconChain

final class ArrayTests: XCTestCase {

    func testSplit() {
        let array = [0, 1, 2, 3]
        XCTAssertEqual([[0, 1], [2, 3]], array.split(count: 2))
    }

}