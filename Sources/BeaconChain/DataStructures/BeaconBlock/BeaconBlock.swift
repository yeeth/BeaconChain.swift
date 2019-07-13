import Foundation

/// This can be thought of as the main container/header for a beacon block.
public struct BeaconBlock {

    /// The slot for which this block is created. Must be greater than the slot of the block defined by `parentRoot`.
    public let slot: Slot

    /// The block root of the parent block, forming a block chain.
    public let parentRoot: Hash

    /// The hash root of the post state of running the state transition through this block.
    public let stateRoot: Hash

    /// Contains all of the aforementioned beacon operations objects as well as a few supplemental fields.
    public let body: BeaconBlockBody

    /// Signature of the block by the block proposer.
    public let signature: BLSSignature
}
