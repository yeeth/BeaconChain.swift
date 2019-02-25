import Foundation

struct Validator {
    let pubkey: Data
    let withdrawalCredentials: Data
    var activationEpoch: UInt64
    var exitEpoch: UInt64
    var withdrawableEpoch: UInt64
    var initiatedExit: Bool
    var slashed: Bool
    
    func isActive(epoch: Epoch) -> Bool {
        return activationEpoch <= epoch && epoch < exitEpoch
    }
}
