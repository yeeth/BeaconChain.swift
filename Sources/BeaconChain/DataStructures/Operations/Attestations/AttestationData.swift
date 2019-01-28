import Foundation

struct AttestationData {
    let slot: UInt64
    let shard: UInt64
    let beaconBlockRoot: Data
    let epochBoundaryRoot: Data
    let shardBlockRoot: Data
    let latestCrosslinkRoot: Data
    let justifiedEpoch: UInt64
    let justifiedBlockRoot: Data
}
