import Foundation

struct AttestationData: Equatable {
    let slot: Slot
    let shard: UInt64
    let beaconBlockRoot: Data
    let epochBoundaryRoot: Data
    let crosslinkDataRoot: Data
    let latestCrosslink: Crosslink
    let justifiedEpoch: Epoch
    let justifiedBlockRoot: Data
}
