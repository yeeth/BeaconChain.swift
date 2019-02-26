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
        let indices = activeIndices(epoch: epoch)
        let size = indices.count

        let shuffled = indices.map {
            indices[BeaconChain.getPermutedIndex(index: Int($0), listSize: size, seed: seed)]
        }

        return shuffled.split(count: BeaconChain.getEpochCommitteeCount(activeValidatorCount: size))
    }
}
