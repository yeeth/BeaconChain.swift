import XCTest
@testable import BeaconChain

final class ValidatorTests: XCTestCase {

    func testIsActive() {
        let epoch = Epoch(10)

        XCTAssertFalse(createValidator(epoch: epoch).isActive(epoch: epoch + 2))
        XCTAssertTrue(createValidator(epoch: epoch).isActive(epoch: epoch))

    }

    func testActivate() {
        var state = BeaconChain.genesisState(
            genesisTime: 0,
            latestEth1Data: Eth1Data(depositRoot: Data(count: 32), blockHash: Data(count: 32)),
            depositLength: 0
        )

        state.slot = 10
        var validator = Validator(
            pubkey: Data(count: 32),
            withdrawalCredentials: Data(count: 32),
            activationEpoch: 0,
            exitEpoch: 0,
            withdrawableEpoch: 0,
            initiatedExit: false,
            slashed: false
        )

        validator.activate(state: state, genesis: false)
        XCTAssertEqual(validator.activationEpoch, 5)
    }


    private func createValidator(epoch: Epoch) -> Validator {
        return Validator(
            pubkey: ZERO_HASH,
            withdrawalCredentials: ZERO_HASH,
            activationEpoch: epoch - 1,
            exitEpoch: epoch + 1,
            withdrawableEpoch: epoch,
            initiatedExit: false,
            slashed: false
        )
    }

}
