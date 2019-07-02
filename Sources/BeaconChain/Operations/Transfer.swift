import Foundation

struct Transfer {
    let sender: ValidatorIndex
    let recipient: ValidatorIndex
    let amount: Gwei
    let fee: Gwei
    let slot: Slot
    let pubkey: BLSPubKey
    let signature: BLSSignature
}
