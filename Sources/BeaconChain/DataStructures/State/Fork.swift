import Foundation

struct Fork {
    let previousVersion: UInt64
    let currentVersion: UInt64
    let epoch: UInt64

    func version(epoch: Epoch) -> UInt64 {
        if epoch < self.epoch {
            return previousVersion
        }

        return currentVersion
    }

    func domain(epoch: Epoch, type: Domain) -> UInt64 {
        return version(epoch: epoch) * 2 ** 32 + type.rawValue
    }
}
