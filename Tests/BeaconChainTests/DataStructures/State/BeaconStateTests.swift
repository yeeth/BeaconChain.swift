import XCTest
@testable import BeaconChain

final class BeaconStateTests: XCTestCase {

    func testPreviousEpoch() {
        var state = BeaconChain.getInitialBeaconState(
            genesisValidatorDeposits: [Deposit](),
            genesisTime: 0,
            latestEth1Data: Eth1Data(depositRoot: ZERO_HASH, blockHash: ZERO_HASH)
        )

        XCTAssertEqual(GENESIS_EPOCH, state.previousEpoch)

        state.slot = GENESIS_SLOT * 2
        XCTAssertEqual((GENESIS_EPOCH * 2) - 1, state.previousEpoch)
    }

    func testCurrentEpoch() {
        var state = BeaconChain.getInitialBeaconState(
            genesisValidatorDeposits: [Deposit](),
            genesisTime: 0,
            latestEth1Data: Eth1Data(depositRoot: ZERO_HASH, blockHash: ZERO_HASH)
        )

        state.slot = GENESIS_SLOT
        XCTAssertEqual(GENESIS_EPOCH, state.currentEpoch)
    }
}
