import Foundation

struct PendingAttestation {
    let data: Data
    let aggregationBitfield: Data
    let custodyBitfield: Data
    let slotIncluded: Int
}
