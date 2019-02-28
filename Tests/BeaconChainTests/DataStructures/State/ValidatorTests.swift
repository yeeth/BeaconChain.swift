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
            latestEth1Data: Eth1Data(depositRoot: ZERO_HASH, blockHash: ZERO_HASH),
            depositLength: 0
        )

        state.slot = 10
        var validator = createValidator(epoch: 1)

        validator.activate(state: state, genesis: false)
        XCTAssertEqual(validator.activationEpoch, 5)
    }

    func testExitValidator() {
        var state = BeaconChain.genesisState(
            genesisTime: 0,
            latestEth1Data: Eth1Data(depositRoot: ZERO_HASH, blockHash: ZERO_HASH),
            depositLength: 0
        )

        state.slot = 100
        var validator = createValidator(epoch: BeaconChain.getCurrentEpoch(state: state).delayedActivationExitEpoch())
        validator.exit(state: state)

        XCTAssertEqual(validator.exitEpoch, BeaconChain.getCurrentEpoch(state: state).delayedActivationExitEpoch())
    }

    func testPrepareForWithdrawal() {
        var state = BeaconChain.genesisState(
            genesisTime: 0,
            latestEth1Data: Eth1Data(depositRoot: ZERO_HASH, blockHash: ZERO_HASH),
            depositLength: 0
        )

        state.slot = 0
        var validator = createValidator(epoch: 1)
        validator.prepareForWithdrawal(state: state)

        XCTAssertEqual(validator.withdrawableEpoch, MIN_VALIDATOR_WITHDRAWABILITY_DELAY)
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
