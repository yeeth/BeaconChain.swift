import Foundation

struct Attestation {
    let aggregationBitfield: Data
    let data: AttestationData
    let custodyBitfield: Data
    let aggregateSignature: Data
}
