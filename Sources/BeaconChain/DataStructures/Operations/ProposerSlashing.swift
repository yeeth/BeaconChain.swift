import Foundation

struct ProposerSlashing: Equatable {
    let proposerIndex: ValidatorIndex
    let header1: BeaconBlockHeader
    let header2: BeaconBlockHeader
}
