import Foundation

public struct Attestation: Equatable {
    let aggregationBitfield: Data
    let data: AttestationData
    let custodyBitfield: Data
    let aggregateSignature: Data
}
