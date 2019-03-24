import Foundation

class LMDGhost: ForkChoice {

    func execute(store: Store, startState: BeaconState, startBlock: BeaconBlock) -> BeaconBlock {
        let targets = startState.validatorRegistry.activeIndices(epoch: startState.slot.toEpoch()).map {
            ($0, store.latestAttestationTarget(validator: $0))
        }

        var head = startBlock
        while true {
            let children = store.children(head)
            if children.count == 0 {
                return head
            }

            head = children.max {
                targets.votes(store: store, state: startState, block: $0) < targets.votes(store: store, state: startState, block: $1)
            }!
        }
    }
}
