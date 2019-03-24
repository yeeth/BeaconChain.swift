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
                attestationTargets.voteCount(store: store, state: startState, block: $0) < attestationTargets.voteCount(store: store, state: startState, block: $1)
            }!
        }
    }
}
