import Foundation

struct Transfer: Equatable {
    let sender: ValidatorIndex
    let recipient: ValidatorIndex
    let amount: Gwei
    let fee: Gwei
    let slot: Slot
    let pubkey: BLSPubkey
    let signature: BLSSignature
}
