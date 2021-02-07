import Foundation

/// The Header of a Beacon Block.
public struct BeaconBlockHeader {

    /// The slot for which this block is created. Must be greater than the slot of the block defined by `parentRoot`.
    public let slot: Slot

    /// The block root of the parent block, forming a block chain.
    public let parentRoot: Hash

    /// The hash root of the post state of running the state transition through this block.
    public let stateRoot: Hash

    /// The hash root of the block body.
    let bodyRoot: Hash

    /// Signature of the block by the block proposer.
    public let signature: BLSSignature
}
