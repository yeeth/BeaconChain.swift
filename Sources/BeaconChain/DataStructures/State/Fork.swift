import Foundation

struct Fork {
    let previousVersion: UInt64
    let currentVersion: UInt64
    let epoch: UInt64

    func domain(epoch: Epoch, type: Domain) -> UInt64 {
        return BeaconChain.getForkVersion(fork: self, epoch: epoch) * 2 ** 32 + type.rawValue
    }
}
