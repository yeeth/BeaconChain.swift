import Foundation

struct Attestation {
    let data: AttestationData
    let participationBitfield: Data
    let custodyBitfield: Data
    let aggregateSignature: Data
}
