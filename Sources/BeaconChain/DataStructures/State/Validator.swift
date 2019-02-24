import Foundation

struct Validator {
    let pubkey: Data
    let withdrawalCredentials: Data
    var activationEpoch: UInt64
    var exitEpoch: UInt64
    let withdrawableEpoch: UInt64
    var slashedEpoch: UInt64
    var statusFlags: UInt64
    
    func isActive(epoch: EpochNumber) -> Bool {
        return self.activationEpoch <= epoch && epoch < self.exitEpoch
    }
}
