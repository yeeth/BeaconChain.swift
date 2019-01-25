import Foundation

struct PendingAttestation {
    let data: AttestationData
    let aggregationBitfield: Data
    let custodyBitfield: Data
    let slotIncluded: UInt64
}
