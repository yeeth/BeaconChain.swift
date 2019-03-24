import Foundation

extension Dictionary where Key == UInt64, Value == Validator {

    func activeIndices(epoch: Epoch) -> [ValidatorIndex] {
        return compactMap {
            (k, v) in
            if v.isActive(epoch: epoch) {
                return k
            }

            return nil
        }
    }
}
