import XCTest
@testable import BeaconChain

final class ArrayValidatorTests: XCTestCase {

    func testActiveIndices() {

        let epoch = EpochNumber(10)

        let validators = [
            createValidator(epoch: epoch),
            createValidator(epoch: epoch),
            createValidator(epoch: EpochNumber(12))
        ]

        XCTAssertEqual(validators.activeIndices(epoch: epoch), [ValidatorIndex(0), 1])
    }

    private func createValidator(epoch: Epoch) -> Validator {
        return Validator(
            pubkey: ZERO_HASH,
            withdrawalCredentials: ZERO_HASH,
            activationEpoch: epoch - 1,
            exitEpoch: epoch + 1,
            withdrawableEpoch: 1,
            slashedEpoch: 0,
            statusFlags: 0
        )
    }
}
