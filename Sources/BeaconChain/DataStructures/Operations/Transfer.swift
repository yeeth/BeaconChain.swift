import Foundation

struct Transfer: Equatable {
    let from: UInt64
    let to: UInt64
    let amount: UInt64
    let fee: UInt64
    let slot: UInt64
    let pubkey: Data
    let signature: Data
}
