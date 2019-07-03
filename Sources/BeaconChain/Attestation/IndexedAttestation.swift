import Foundation

public struct IndexedAttestation {
    let custodyBit0Indices: [ValidatorIndex]
    let custodyBit1Indices: [ValidatorIndex]
    let data: AttestationData
    let signature: BLSSignature
}
