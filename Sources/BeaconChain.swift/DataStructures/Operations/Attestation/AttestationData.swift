import Foundation

struct AttestationData {
    let slot: Int
    let shard: Int
    let beaconBlockRoot: Data
    let epochBoundryRoot: Data
    let shardBlockRoot: Data
    let latestCrosslinkRoot: Data
    let justifiedSlot: uint64
    let justifiedBlockRoot: Data
}
