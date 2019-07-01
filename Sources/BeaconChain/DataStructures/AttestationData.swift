import Foundation

struct AttestationData: Equatable {
    let beaconBlockRoot: Data
    let source: Checkpoint
    let target: Checkpoint
    let crosslink: Crosslink
}
