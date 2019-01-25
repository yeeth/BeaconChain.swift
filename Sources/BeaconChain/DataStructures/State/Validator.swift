import Foundation

struct Validator {
    let pubkey: Data
    let withdrawalCredentials: Data
    var randaoCommitment: Data
    var randaoLayers: Int
    var activationSlot: Int
    var exitSlot: Int
    let withdrawalSlot: Int
    var penalizedSlot: Int
    var exitCount: Int
    var statusFlags: Int
    let custodyCommitment: Data
    let latestCustodyReseedSlot: Int
    let penultimateCustodyReseedSlot: Int
}
