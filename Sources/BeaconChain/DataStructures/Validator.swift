import Foundation

/// A validator is an entity that participates in the consensus of the Ethereum 2.0 protocol.
struct Validator {

    let pubkey: BLSPubKey
    let withdrawalCredentials: Hash
    let effectiveBalance: Gwei
    let slashed: Bool
    let activationEligibilityEpoch: Epoch
    let activationEpoch: Epoch
    let exitEpoch: Epoch
    let withdrawableEpoch: Epoch

    /// Checks if a `validator` is active.
    ///
    /// - Parameters:
    ///     - epoch: The given epoch to check activation for.
    func isActive(epoch: Epoch) -> Bool {
        return activationEpoch <= epoch && epoch < exitEpoch
    }

    /// Checks if a `validator` is slashable.
    ///
    /// - Parameters:
    ///     - epoch: The given epoch to check slashability for.
    func isSlashable(epoch: Epoch) -> Bool {
        return !slashed && activationEpoch <= epoch && epoch < withdrawableEpoch
    }
}
