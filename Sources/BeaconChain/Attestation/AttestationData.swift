import Foundation

struct AttestationData {
    let beaconBlockRoot: Hash
    let source: Checkpoint
    let target: Checkpoint
    let crosslink: Crosslink
}
