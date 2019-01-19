import Foundation

class AttestationData: Equatable {
    let slot: Int
    let shard: Int
    let beaconBlockRoot: Data
    let epochBoundryRoot: Data
    let shardBlockRoot: Data
    let latestCrosslinkRoot: Data
    let justifiedSlot: Int
    let justifiedBlockRoot: Data

    init(
        slot: Int,
        shard: Int,
        beaconBlockRoot: Data,
        epochBoundryRoot: Data,
        shardBlockRoot: Data,
        latestCrosslinkRoot: Data,
        justifiedSlot: Int,
        justifiedBlockRoot: Data
    ) {
        self.slot = slot
        self.shard = shard
        self.beaconBlockRoot = beaconBlockRoot
        self.epochBoundryRoot = epochBoundryRoot
        self.shardBlockRoot = shardBlockRoot
        self.latestCrosslinkRoot = latestCrosslinkRoot
        self.justifiedSlot = justifiedSlot
        self.justifiedBlockRoot = justifiedBlockRoot
    }

    static func == (lhs: AttestationData, rhs: AttestationData) -> Bool {
        return lhs.slot == rhs.slot
            && lhs.shard == rhs.shard
            && lhs.beaconBlockRoot == rhs.beaconBlockRoot
            && lhs.epochBoundryRoot == rhs.epochBoundryRoot
            && lhs.shardBlockRoot == rhs.shardBlockRoot
            && lhs.latestCrosslinkRoot == rhs.latestCrosslinkRoot
            && lhs.justifiedSlot == rhs.justifiedSlot
            && lhs.justifiedBlockRoot == rhs.justifiedBlockRoot
    }
}
