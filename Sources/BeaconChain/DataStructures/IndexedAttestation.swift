import Foundation

struct IndexedAttestation: Equatable {
    let custodyBit0Indices = [ValidatorIndex](repeating: 0, count: Int(MAX_VALIDATORS_PER_COMMITTEE))
    let custodyBit1Indices = [ValidatorIndex](repeating: 0, count: Int(MAX_VALIDATORS_PER_COMMITTEE))
    let data: AttestationData
    let signature: BLSSignature
}
