import Foundation

/// Message type that allows a validator to voluntarily exit validation duties.
public struct VoluntaryExit {

    /// Minimum epoch at which this exit can be included on chain. Helps prevent accidental/nefarious use in chain reorgs/forks.
    public let epoch: Epoch

    /// Index of validator exiting.
    public let validatorIndex: ValidatorIndex

    /// Signature of the `VoluntaryExit` by the pubkey associated with the
    public let signature: BLSSignature
}
