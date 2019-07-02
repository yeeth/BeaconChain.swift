import Foundation

struct VoluntaryExit {
    let epoch: Epoch
    let validatorIndex: ValidatorIndex
    let signature: BLSSignature
}
