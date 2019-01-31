import Foundation

struct Validator {
    let pubkey: Data
    let withdrawalCredentials: Data
    var activationEpoch: UInt64
    var exitEpoch: UInt64
    let withdrawalEpoch: UInt64
    var penalizedEpoch: UInt64
    var exitCount: UInt64
    var statusFlags: UInt64
    let latestCustodyReseedSlot: UInt64
    let penultimateCustodyReseedSlot: UInt64
}
