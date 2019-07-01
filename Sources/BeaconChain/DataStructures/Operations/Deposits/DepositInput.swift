import Foundation

struct DepositInput: Equatable {
    let pubkey: Data
    let withdrawalCredentials: Data
    let proofOfPossession: Data
}
