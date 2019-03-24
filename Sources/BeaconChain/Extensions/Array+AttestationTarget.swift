import Foundation

extension Array where Element == AttestationTarget {

    func votes(store: Store, state: BeaconState, block: BeaconBlock) -> UInt64 {
        return compactMap {
            (index, target) in

            guard store.ancestor(block: target, slot: target.slot) == block else {
                return nil
            }

            return BeaconChain.getEffectiveBalance(state: state, index: index) / FORK_CHOICE_BALANCE_INCREMENT
        }
        .reduce(0, +)
    }
}
