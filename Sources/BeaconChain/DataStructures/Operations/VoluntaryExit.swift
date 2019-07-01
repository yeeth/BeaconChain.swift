import Foundation

struct VoluntaryExit: Equatable {
    let epoch: UInt64
    let validatorIndex: ValidatorIndex
    let signature: BLSSignature
}
