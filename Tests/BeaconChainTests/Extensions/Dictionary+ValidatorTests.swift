import XCTest
@testable import BeaconChain

final class DictionaryValidatorTests: XCTestCase {

    func testActiveIndices() {

        let epoch = Epoch(10)

        let validators = [
            UInt64(0): createValidator(epoch: epoch),
            1: createValidator(epoch: epoch),
            2: createValidator(epoch: Epoch(12))
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
            initiatedExit: false,
            slashed: false
        )
    }
}
