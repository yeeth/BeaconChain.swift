import Foundation

public struct BeaconBlockBody {

    /// The signature of the current epoch (by the block proposer) and,
    /// when mixed in with the other validators’ reveals, consitutes the seed for randomness.
    public let randaoReveal: BLSSignature

    /// A vote on recent data the Eth1 chain.
    public let eth1Data: Eth1Data

    /// This is a space for validators to decorate as they choose. It has no define in-protocol use.
    public let graffiti: Data

    public let proposerSlashings: [ProposerSlashing]
    public let attesterSlashings: [AttesterSlashing]
    public let attestations: [Attestation]
    public let deposits: [Deposit]
    public let voluntaryExits: [VoluntaryExit]
    public let transfers: [Transfer]
}
