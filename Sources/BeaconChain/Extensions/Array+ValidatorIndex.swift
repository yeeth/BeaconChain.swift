import Foundation

extension Array where Element == ValidatorIndex {

    func totalBalance(state: BeaconState) -> Gwei {
        return map { state.effectiveBalance($0) }.reduce(0, +)
    }
}
