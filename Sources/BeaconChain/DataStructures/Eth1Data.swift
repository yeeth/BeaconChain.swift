import Foundation

/// A vote on recent data the Eth1 chain.
public struct Eth1Data {

    /// The SSZ List hash_tree_root of the deposits in the deposit contract.
    public let depositRoot: Hash

    /// The number of deposits that have occured thusfar.
    public let depositCount: UInt64

    /// The eth1 block hash that contained the deposit_root.  This block_hash
    /// might be used for finalization of the Eth1 chain in the future (similar to how the FFG contract was going to
    /// be used to finalize the eth1 chain).
    public let blockHash: Hash
}
