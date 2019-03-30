import Foundation

struct Transfer: Equatable {
    let sender: UInt64
    let recipient: UInt64
    let amount: UInt64
    let fee: UInt64
    let slot: UInt64
    let pubkey: Data
    let signature: Data
}
