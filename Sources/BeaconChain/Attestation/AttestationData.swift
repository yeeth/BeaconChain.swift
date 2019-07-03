import Foundation

/// AttestationData is the main component that is signed by each validator.
public struct AttestationData {

    /// Block root of the beacon block seen as the head of the chain at the assigned slot.
    public let beaconBlockRoot: Hash

    /// The most recent justified checkpoint in the BeaconState at the assigned slot.
    public let source: Checkpoint

    /// The checkpoint attempting to be justified (the current epoch and epoch boundary block).
    public let target: Checkpoint

    /// The crosslink attemping to be formed for the assigned shard.
    public let crosslink: Crosslink
}
