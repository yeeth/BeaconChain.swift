import Foundation

extension Array where Element == AttestationTarget {

    func voteCount(store: Store, state: BeaconState, block: BeaconBlock) -> UInt64 {
        return compactMap {
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