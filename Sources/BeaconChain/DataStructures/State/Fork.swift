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
}
