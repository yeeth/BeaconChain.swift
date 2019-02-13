import Foundation

extension Array where Element == ValidatorIndex {

    func totalBalance(state: BeaconState) -> Gwei {
        return self.map {
            return BeaconChain.getEffectiveBalance(state: state, index: $0)
        }
        .reduce(0, +)
    }
}
