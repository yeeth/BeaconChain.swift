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
}
