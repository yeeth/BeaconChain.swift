import XCTest
@testable import BeaconChain

class PowerTests: XCTestCase {

    let tests: [(base: Int, exponent: Int, expected: Int)] = [
        (2, 0, 1),
        (2, 1, 2),
        (2, 2, 4),
        (2, 3, 8),
        (2, 4, 16),
    ];

    func testPowerForInt() {
        for test in tests {
            XCTAssert(test.base ** test.exponent == test.expected)
        }
    }

    func testPowerForUInt64() {
        for test in tests {
            XCTAssert(UInt64(test.base) ** UInt64(test.exponent) == UInt64(test.expected))
        }
    }

}
