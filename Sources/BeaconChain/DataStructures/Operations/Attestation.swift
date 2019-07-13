import Foundation

/// Primary message type that validators create for consensus.
public struct Attestation {

    /// Stores a single bit for each member of the committee assigning a value of 1 to each validator that participated
    /// in this aggregate signature.
    public let aggregationBits: [Bool]

    /// The AttestationData that was signed by the validator or committee of validators.
    public let data: AttestationData

    /// Represents each committee member’s “proof of custody” bit (0 if non-participating).
    public let custodyBits: [Bool]

    /// The aggregate BLS signature of the data.
    public let signature: BLSSignature
}
