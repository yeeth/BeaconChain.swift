import Foundation

struct DepositData {
    let pubkey: BLSPubKey
    let withdrawalCredentials: Hash
    let amount: Gwei
    let signature: BLSSignature
}
