import Foundation

struct ProposerSlashing: Equatable {
    let proposerIndex: UInt64
    let header1: BeaconBlockHeader
    let header2: BeaconBlockHeader
}
