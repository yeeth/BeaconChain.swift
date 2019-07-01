import Foundation

struct PendingAttestation {
    let aggregationBits = Array(repeating: false, count: Int(MAX_VALIDATORS_PER_COMMITTEE))
    let data: AttestationData
    let inclusionDelay: Slot
    let proposerIndex: ValidatorIndex
}
