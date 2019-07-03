import Foundation

/// The DepositData submit to the deposit contract to be verified using the proof against the deposit root.
public struct DepositData {

    /// BLS12-381 pubkey to be used to sign messages by the validator.
    let pubkey: BLSPubKey

    /// The hash of an offline pubkey to be used to withdraw the staked funds after exiting.
    /// This key is not used actively in validation and can be kept in cold storage.
    let withdrawalCredentials: Hash

    /// Amount in Gwei that was deposited.
    let amount: Gwei

    /// This is used as a one-time “proof of custody” required for securely using BLS keys.
    let signature: BLSSignature
}
