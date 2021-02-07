import Foundation

class Deposits: BlockTransitions {

    static func transition(state: inout BeaconState, block: BeaconBlock) {
        assert(block.body.deposits.count <= MAX_DEPOSITS)

        for deposit in block.body.deposits {
            let serializedDepositData = Data(count: 64) // @todo when we have SSZ

            assert(
                StateTransition.verifyMerkleBranch(
                    leaf: BeaconChain.hash(serializedDepositData),
                    branch: deposit.branch,
                    depth: Int(DEPOSIT_CONTRACT_TREE_DEPTH),
                    index: Int(deposit.index),
                    root: state.latestEth1Data.depositRoot
                )
            )

            BeaconChain.processDeposit(
                state: &state,
                deposit: deposit
            )

            state.depositIndex += 1
        }
    }
}
