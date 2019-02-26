import Foundation

extension Array where Element == Validator {

    func activeIndices(epoch: Epoch) -> [ValidatorIndex] {
        return enumerated().compactMap {
            (k, v) in
            if v.isActive(epoch: epoch) {
                return ValidatorIndex(k)
            }

            return nil
        }
    }

    func shuffling(seed: Bytes32, epoch: Epoch) -> [[ValidatorIndex]] {
        let activeValidatorIndices = activeIndices(epoch: epoch)

        let shuffledActiveValidatorIndices = activeValidatorIndices.map {
            activeValidatorIndices[BeaconChain.getPermutedIndex(index: Int($0), listSize: activeValidatorIndices.count, seed: seed)]
        }

        return shuffledActiveValidatorIndices.split(
            count: BeaconChain.getEpochCommitteeCount(activeValidatorCount: activeValidatorIndices.count)
        )
    }
}
