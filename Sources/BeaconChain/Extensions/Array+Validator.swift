import Foundation

extension Array where Element == Validator {

    func activeIndices(epoch: EpochNumber) -> [ValidatorIndex] {
        return enumerated().compactMap {
            (k, v) in
            if BeaconChain.isActive(validator: v, epoch: epoch) {
                return ValidatorIndex(k)
            }

            return nil
        }
    }
}
