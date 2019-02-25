import Foundation

struct Validator {
    let pubkey: Data
    let withdrawalCredentials: Data
    var activationEpoch: UInt64
    var exitEpoch: UInt64
    var withdrawableEpoch: UInt64
    var slashedEpoch: UInt64
    var statusFlags: UInt64
    
    func isActive(epoch: Epoch) -> Bool {
        return activationEpoch <= epoch && epoch < exitEpoch
    }
}
