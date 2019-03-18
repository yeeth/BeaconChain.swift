import Foundation

struct SlashableAttestation: Equatable {
    let validatorIndices: [UInt64]
    let data: AttestationData
    let custodyBitfield: Data
    let aggregateSignature: Data
}
