import Foundation

struct PendingAttestation {
    let data: Data
    let participationBitfield: Data
    let custodyBitfield: Data
    let slotIncluded: Int
}
