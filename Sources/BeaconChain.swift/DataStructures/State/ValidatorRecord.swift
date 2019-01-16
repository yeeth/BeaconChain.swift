import Foundation

struct ValidatorRecord {
    let pubkey: Data
    let withdrawalCredentials: Data
    let randaoCommitment: Data
    let randaoLayers: Int
    var activationSlot: Int
    var exitSlot: Int
    let withdrawalSlot: Int
    var penalizedSlot: Int
    let exitCount: Int
    var statusFlags: Int
    let custodyCommitment: Data
    let latestCustodyReseedSlot: Int
    let penultimateCustodyReseedSlot: Int
}
