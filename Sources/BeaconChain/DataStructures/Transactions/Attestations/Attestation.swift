import Foundation

struct Attestation: Equatable {
    let aggregationBitfield: Data
    let data: AttestationData
    let custodyBitfield: Data
    let aggregateSignature: Data
}
