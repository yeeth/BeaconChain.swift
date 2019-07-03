import Foundation

/// Beacon block proposers can be slashed if they signed two different beacon blocks for the same epoch.
/// ProposerSlashing contains proof that such a slashable offense has occurred.
public struct ProposerSlashing {

    /// `ValidatorIndex` of the validator to be slashed for double proposing.
    public let proposerIndex: ValidatorIndex

    /// The header of the first of the two slashable beacon blocks.
    public let header1: BeaconBlockHeader

    /// The header of the second of the two slashable beacon blocks.
    public let header2: BeaconBlockHeader
}
