import Foundation

struct Fork {
    let previousVersion: Data
    let currentVersion: Data
    let epoch: UInt64

    func version(epoch: Epoch) -> Data {
        if epoch < self.epoch {
            return previousVersion
        }

        return currentVersion
    }

    func domain(epoch: Epoch, type: Domain) -> UInt64 {
        return version(epoch: epoch).withUnsafeBytes { $0.pointee } * 2 ** 32 + type.rawValue
    }
}
