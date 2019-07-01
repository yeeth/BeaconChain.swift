import Foundation

struct DepositData: Equatable {
    let pubkey: BLSPubkey
    let withdrawalCredentials: Data
    let amount: Gwei
    let signature: BLSSignature
}
