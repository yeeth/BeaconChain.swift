import XCTest
@testable import BeaconChain

class ValidatorTests: XCTestCase {

    func testIsActive() {
        let validator = Validator(
            pubkey: BLSPubKey(repeating: 0, count: 0),
            withdrawalCredentials: Hash(repeating: 0, count: 0),
            effectiveBalance: 0,
            slashed: false,
            activationEligibilityEpoch: 0,
            activationEpoch: 10,
            exitEpoch: 15,
            withdrawableEpoch: 10
        )

        XCTAssertTrue(validator.isActive(epoch: 11))
    }

    func testIsSlashable() {

        let tests: [(slashed: Bool, activationEpoch: Epoch, withdrawalEpoch: Epoch, epoch: Epoch, expected: Bool)] = [
            (false, 10, 10, 11, false),
            (true, 10, 10, 11, false),
            (false, 10, 12, 10, true)
        ]

        for test in tests {
            let validator = Validator(
                    pubkey: BLSPubKey(repeating: 0, count: 0),
                    withdrawalCredentials: Hash(repeating: 0, count: 0),
                    effectiveBalance: 0,
                    slashed: test.slashed,
                    activationEligibilityEpoch: 0,
                    activationEpoch: test.activationEpoch,
                    exitEpoch: 10,
                    withdrawableEpoch: test.withdrawalEpoch
            )

            XCTAssertEqual(test.expected, validator.isSlashable(epoch: test.epoch))
        }

    }

}
