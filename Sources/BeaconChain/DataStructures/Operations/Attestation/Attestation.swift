import Foundation

struct Attestation {
    let data: AttestationData
    let aggregationBitfield: Data
    let custodyBitfield: Data
    let aggregateSignature: Data
}
