import Foundation

struct Fork {
    let previousVersion: Version
    let currentVersion: Version
    let epoch: Epoch

    func version(epoch: Epoch) -> Version {
        if epoch < self.epoch {
            return previousVersion
        }

        return currentVersion
    }

//    func domain(epoch: Epoch, type: Domain) -> UInt64 {
//        return version(epoch: epoch) * 2 ** 32 + type.rawValue
//    }
}
