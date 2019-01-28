import Foundation

struct Validator {
    let pubkey: Data
    let withdrawalCredentials: Data
    let activationEpoch: UInt64
    let exitEpoch: UInt64
    let withdrawalEpoch: UInt64
    let penalizedEpoch: UInt64
    let exitCount: UInt64
    let statusFlags: UInt64
    let latestCustodyReseedSlot: UInt64
    let penultimateCustodyReseedSlot: UInt64
}
