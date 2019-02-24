import Foundation

extension Array where Element == ValidatorIndex {

    func totalBalance(state: BeaconState) -> Gwei {
        return map { BeaconChain.getEffectiveBalance(state: state, index: $0) }.reduce(0, +)
    }
}
