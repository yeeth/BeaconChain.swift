import Foundation

struct Attestation {
    let aggregationBits: [Bool]
    let data: AttestationData
    let custodyBits: [Bool]
    let signature: BLSSignature
}
