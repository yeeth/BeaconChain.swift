import XCTest
@testable import BeaconChain

final class ValidatorTests: XCTestCase {

    func testIsActive() {
        let epoch = EpochNumber(10)

        XCTAssertFalse(createValidator(epoch: epoch).isActive(epoch: epoch + 2))
        XCTAssertTrue(createValidator(epoch: epoch).isActive(epoch: epoch))

    }

    private func createValidator(epoch: EpochNumber) -> Validator {
        return Validator(
            pubkey: ZERO_HASH,
            withdrawalCredentials: ZERO_HASH,
            activationEpoch: epoch - 1,
            exitEpoch: epoch + 1,
            withdrawableEpoch: epoch,
            slashedEpoch: epoch,
            statusFlags: 0
        )
    }

}
