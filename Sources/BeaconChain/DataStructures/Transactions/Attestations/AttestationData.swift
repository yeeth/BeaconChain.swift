import Foundation

struct AttestationData: Equatable {
    let slot: Slot
    let beaconBlockRoot: Data
    let sourceEpoch: UInt64
    let sourceRoot: Data
    let targetRoot: Data
    let shard: UInt64
    let previousCrosslink: Crosslink
    let crosslinkDataRoot: Data
}
