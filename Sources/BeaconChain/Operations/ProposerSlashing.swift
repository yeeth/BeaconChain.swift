import Foundation

struct ProposerSlashing {
    let proposerIndex: ValidatorIndex
    let header1: BeaconBlockHeader
    let header2: BeaconBlockHeader
}
