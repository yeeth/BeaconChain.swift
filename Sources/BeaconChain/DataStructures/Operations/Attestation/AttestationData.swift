import Foundation

public class AttestationData: Equatable {
    let slot: UInt64
    let shard: UInt64
    let beaconBlockRoot: Data
    let epochBoundryRoot: Data
    let shardBlockRoot: Data
    let latestCrosslinkRoot: Data
    let justifiedSlot: UInt64
    let justifiedBlockRoot: Data

    init(
        slot: UInt64,
        shard: UInt64,
        beaconBlockRoot: Data,
        epochBoundryRoot: Data,
        shardBlockRoot: Data,
        latestCrosslinkRoot: Data,
        justifiedSlot: UInt64,
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

    public static func == (lhs: AttestationData, rhs: AttestationData) -> Bool {
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
