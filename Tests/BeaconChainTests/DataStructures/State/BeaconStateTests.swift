import XCTest
@testable import BeaconChain

final class BeaconStateTests: XCTestCase {

    func testPreviousEpoch() {
        var state = getState()
        XCTAssertEqual(GENESIS_EPOCH, state.previousEpoch)

        state.slot = GENESIS_SLOT * 2
        XCTAssertEqual((GENESIS_EPOCH * 2) - 1, state.previousEpoch)
    }

    func testCurrentEpoch() {
        var state = getState()
        state.slot = GENESIS_SLOT
        XCTAssertEqual(GENESIS_EPOCH, state.currentEpoch)
    }

    private func getState() -> BeaconState {
        return BeaconChain.getInitialBeaconState(
            genesisValidatorDeposits: [Deposit](),
            genesisTime: 0,
            latestEth1Data: Eth1Data(depositRoot: ZERO_HASH, blockHash: ZERO_HASH)
        )
    }
}
