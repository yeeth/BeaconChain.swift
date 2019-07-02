import Foundation

struct PendingAttestation {
    let aggregationBits: [Bool]
    let data: AttestationData
    let inclusionDelay: Slot
    let proposerIndex: ValidatorIndex
}
