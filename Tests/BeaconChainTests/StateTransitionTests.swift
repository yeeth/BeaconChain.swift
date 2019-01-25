import XCTest
@testable import BeaconChain

final class StateTransitionTests: XCTestCase {

    func testBaseReward() {
        let tests = [
            (UInt64(0), UInt64(0)),
            (MIN_DEPOSIT_AMOUNT, UInt64(61)),
            (MAX_DEPOSIT_AMOUNT, UInt64(1976)),
            (UInt64(40 * 1e9), UInt64(1976))
        ]

        for test in tests {
            let state = BeaconChain.genesisState(
                genesisTime: TimeInterval(0),
                latestEth1Data: Eth1Data(depositRoot: Data(count: 32), blockHash: Data(count: 32))
            )

            state.validatorBalances.append(test.0)

            XCTAssertEqual(test.1, StateTransition.baseReward(state: state, index: 0, baseRewardQuotient: 3237888))
        }
    }

    func testInactivityPenalty() {
        let tests = [
            (UInt64(1), UInt64(2929)),
            (UInt64(2), UInt64(3883)),
            (UInt64(5), UInt64(6744)),
            (UInt64(10), UInt64(11512)),
            (UInt64(50), UInt64(49659))
        ] as [(UInt64, UInt64)]

        for test in tests {
            let state = BeaconChain.genesisState(
                genesisTime: TimeInterval(0),
                latestEth1Data: Eth1Data(depositRoot: Data(count: 32), blockHash: Data(count: 32))
            )

            state.validatorBalances.append(MAX_DEPOSIT_AMOUNT)

            XCTAssertEqual(
                test.1,
                StateTransition.inactivityPenalty(
                    state: state,
                    index: 0,
                    epochsSinceFinality: test.0,
                    baseRewardQuotient: 3237888
                )
            )
        }
    }
}
