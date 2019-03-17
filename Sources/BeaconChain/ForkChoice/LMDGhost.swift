import Foundation

class LMDGhost: ForkChoice {

    func execute(store: Store, startState: BeaconState, startBlock: BeaconBlock) -> BeaconBlock {
        let attestationTargets = startState.validatorRegistry.activeIndices(epoch: startState.slot.toEpoch()).map {
            ($0, store.latestAttestationTarget(validator: $0))
        }

        var head = startBlock
        while true {
            let children = store.children(head)
            if children.count == 0 {
                return head
            }

            head = children.max {
                voteCount(store: store, state: startState, block: $0, attestationTargets: attestationTargets) < voteCount(store: store, state: startState, block: $1, attestationTargets: attestationTarget)
            }!
        }
    }

    private func voteCount(
        store: Store,
        state: BeaconState,
        block: BeaconBlock,
        attestationTargets: [(ValidatorIndex, BeaconBlock)]
    ) -> UInt64 {
        return attestationTargets.compactMap {
            (index, target) in
            guard let ancestor = store.ancestor(block: target, slot: index) else {
                return nil
            }

            if ancestor == block {
                return BeaconChain.getEffectiveBalance(state: state, index: index) / FORK_CHOICE_BALANCE_INCREMENT
            }

            return nil
        }
        .reduce(0, +)
    }
}
