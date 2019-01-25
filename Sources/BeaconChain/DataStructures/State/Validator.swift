import Foundation

public struct Validator {
    let pubkey: Data
    let withdrawalCredentials: Data
    var randaoCommitment: Data
    var randaoLayers: UInt64
    var activationSlot: UInt64
    var exitSlot: UInt64
    let withdrawalSlot: UInt64
    var penalizedSlot: UInt64
    var exitCount: UInt64
    var statusFlags: UInt64
    let custodyCommitment: Data
    let latestCustodyReseedSlot: UInt64
    let penultimateCustodyReseedSlot: UInt64
}
