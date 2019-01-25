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

    func testExpectedFFGTarget() {
        // @todo check these numbers
        let tests = [
            ([Int](), [31999427550, 31999427550, 31999427550, 31999427550]),
            ([0,1], [32000286225, 32000286225, 31999427550, 31999427550]),
            ([0,1,2,3], [32000572450, 32000572450, 32000572450, 32000572450])
        ] as [([Int], [UInt64])]

        for test in tests {
            let state = BeaconChain.genesisState(
                genesisTime: TimeInterval(0),
                latestEth1Data: Eth1Data(depositRoot: Data(count: 32), blockHash: Data(count: 32))
            )

            for _ in 0..<4 {
                state.validatorBalances.append(MAX_DEPOSIT_AMOUNT)
                state.validatorRegistry.append(
                    Validator(
                        pubkey: Data(count: 32),
                        withdrawalCredentials: Data(count: 32),
                        randaoCommitment: Data(count: 32),
                        randaoLayers: 0,
                        activationSlot: 0,
                        exitSlot: FAR_FUTURE_SLOT,
                        withdrawalSlot: 0,
                        penalizedSlot: 0,
                        exitCount: 0,
                        statusFlags: 0,
                        custodyCommitment: Data(count: 32),
                        latestCustodyReseedSlot: 0,
                        penultimateCustodyReseedSlot: 0
                    )
                )
            }

            let totalBalance = MAX_DEPOSIT_AMOUNT * UInt64(test.1.count)

            let newState = StateTransition.expectedFFGTarget(
                state: state,
                previousEpochBoundaryAttesterIndices: test.0,
                activeValidators: Set([0,1,2,3]),
                previousEpochBoundaryAttestingBalance: MAX_DEPOSIT_AMOUNT * UInt64(test.0.count),
                baseRewardQuotient: StateTransition.baseRewardQuotient(totalBalance: totalBalance),
                totalBalance: totalBalance
            )

            for (i, balance) in test.1.enumerated() {
                XCTAssertEqual(balance, newState.validatorBalances[i])
            }
        }
    }
  
    func testExpectedFFGSource() {
        // @todo check these numbers
        let tests = [
            ([Int](), [31999427550, 31999427550, 31999427550, 31999427550]),
            ([0,1], [32000286225, 32000286225, 31999427550, 31999427550]),
            ([0,1,2,3], [32000572450, 32000572450, 32000572450, 32000572450])
            ] as [([Int], [UInt64])]

        for test in tests {
            let state = BeaconChain.genesisState(
                genesisTime: TimeInterval(0),
                latestEth1Data: Eth1Data(depositRoot: Data(count: 32), blockHash: Data(count: 32))
            )

            for _ in 0..<4 {
                state.validatorBalances.append(MAX_DEPOSIT_AMOUNT)
                state.validatorRegistry.append(
                    Validator(
                        pubkey: Data(count: 32),
                        withdrawalCredentials: Data(count: 32),
                        randaoCommitment: Data(count: 32),
                        randaoLayers: 0,
                        activationSlot: 0,
                        exitSlot: FAR_FUTURE_SLOT,
                        withdrawalSlot: 0,
                        penalizedSlot: 0,
                        exitCount: 0,
                        statusFlags: 0,
                        custodyCommitment: Data(count: 32),
                        latestCustodyReseedSlot: 0,
                        penultimateCustodyReseedSlot: 0
                    )
                )
            }

            let totalBalance = MAX_DEPOSIT_AMOUNT * UInt64(test.1.count)

            let newState = StateTransition.expectedFFGSource(
                state: state,
                previousEpochJustifiedAttesterIndices: test.0,
                activeValidators: Set([0,1,2,3]),
                previousEpochJustifiedAttestingBalance: MAX_DEPOSIT_AMOUNT * UInt64(test.0.count),
                baseRewardQuotient: StateTransition.baseRewardQuotient(totalBalance: totalBalance),
                totalBalance: totalBalance
            )

            for (i, balance) in test.1.enumerated() {
                XCTAssertEqual(balance, newState.validatorBalances[i])
            }
        }
    }

    func testExpectedBeaconChainHead() {
        // @todo check these numbers
        let tests = [
            ([Int](), [31999427550, 31999427550, 31999427550, 31999427550]),
            ([0,1], [32000286225, 32000286225, 31999427550, 31999427550]),
            ([0,1,2,3], [32000572450, 32000572450, 32000572450, 32000572450])
            ] as [([Int], [UInt64])]

        for test in tests {
            let state = BeaconChain.genesisState(
                genesisTime: TimeInterval(0),
                latestEth1Data: Eth1Data(depositRoot: Data(count: 32), blockHash: Data(count: 32))
            )

            for _ in 0..<4 {
                state.validatorBalances.append(MAX_DEPOSIT_AMOUNT)
                state.validatorRegistry.append(
                    Validator(
                        pubkey: Data(count: 32),
                        withdrawalCredentials: Data(count: 32),
                        randaoCommitment: Data(count: 32),
                        randaoLayers: 0,
                        activationSlot: 0,
                        exitSlot: FAR_FUTURE_SLOT,
                        withdrawalSlot: 0,
                        penalizedSlot: 0,
                        exitCount: 0,
                        statusFlags: 0,
                        custodyCommitment: Data(count: 32),
                        latestCustodyReseedSlot: 0,
                        penultimateCustodyReseedSlot: 0
                    )
                )
            }

            let totalBalance = MAX_DEPOSIT_AMOUNT * UInt64(test.1.count)

            let newState = StateTransition.expectedBeaconChainHead(
                state: state,
                previousEpochHeadAttesterIndices: test.0,
                activeValidators: Set([0,1,2,3]),
                previousEpochHeadAttestingBalance: MAX_DEPOSIT_AMOUNT * UInt64(test.0.count),
                baseRewardQuotient: StateTransition.baseRewardQuotient(totalBalance: totalBalance),
                totalBalance: totalBalance
            )

            for (i, balance) in test.1.enumerated() {
                XCTAssertEqual(balance, newState.validatorBalances[i])
            }
        }
    }
}
