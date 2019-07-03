import Foundation

/// Allows validators to transfer balances.
public struct Transfer {

    /// Validator index of the sender of funds.
    public let sender: ValidatorIndex

    /// Validator index of the recipient of funds.
    public let recipient: ValidatorIndex

    /// Amount in Gwei to send.
    public let amount: Gwei

    /// Fee in Gwei to be paid to the block proposer for including the transfer.
    public let fee: Gwei

    /// The specific slot that this signed `Transfer` can be included on chain. prevents replay attacks.
    public let slot: Slot

    /// The withdrawal pubkey of the sender. The hash of this pubkey must match the senders withdrawalCredentials.
    public let pubkey: BLSPubKey

    /// The signature of the `Transfer` signed by the `transfer.pubkey`.
    public let signature: BLSSignature
}
