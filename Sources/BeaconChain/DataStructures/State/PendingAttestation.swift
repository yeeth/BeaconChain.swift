import Foundation

struct PendingAttestation {
    let aggregationBitfield: Data
    let data: AttestationData
    let custodyBitfield: Data
    let inclusionSlot: UInt64
}
