import Foundation

struct DepositInput {
    let pubkey: Data
    let withdrawalCredentials: Data
    let randaoCommitment: Data
    let custodyCommitment: Data
    let proofOfPossession: Data
}
