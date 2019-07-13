import Foundation

struct Validator {
    let pubkey: BLSPubKey
    let withdrawalCredentials: Hash
    let effectiveBalance: Gwei
    let slashed: Bool
    let activationEligibilityEpoch: Epoch
    let activationEpoch: Epoch
    let exitEpoch: Epoch
    let withdrawableEpoch: Epoch
}
