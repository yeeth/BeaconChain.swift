import Foundation

struct PendingAttestationRecord {
    let data: Data
    let participationBitfield: Data
    let custodyBitfield: Data
    let slotIncluded: Int
}
