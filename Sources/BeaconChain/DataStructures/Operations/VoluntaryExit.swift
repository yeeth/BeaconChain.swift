import Foundation

struct VoluntaryExit: Equatable {
    let epoch: UInt64
    let validatorIndex: UInt64
    let signature: Data
}
