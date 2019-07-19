import Foundation

/// AttestationData is the main component that is signed by each validator.
public struct AttestationData: Equatable {

    /// Block root of the beacon block seen as the head of the chain at the assigned slot.
    public let beaconBlockRoot: Hash

    /// The most recent justified checkpoint in the BeaconState at the assigned slot.
    public let source: Checkpoint

    /// The checkpoint attempting to be justified (the current epoch and epoch boundary block).
    public let target: Checkpoint

    /// The crosslink attempting to be formed for the assigned shard.
    public let crosslink: Crosslink

    /// Check if ``self`` and ``data`` are slashable according to Casper FFG rules.
    ///
    /// - Parameters
    ///     - data: `AttestationData` to compare to.
    func isSlashable(_ data: AttestationData) -> Bool {
        return (self != data && target.epoch == data.target.epoch)
            && (source.epoch < data.source.epoch && data.target.epoch < target.epoch)
    }
}
