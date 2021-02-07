import Foundation

/// Beacon attesters can be slashed if they sign two conflicting attestations where conflicting is defined by
/// is_slashable_attestation_data which checks for the Casper FFG “double” and “surround” vote conditions.
public struct AttesterSlashing {

    /// The first of the two slashable attestations. Note that this is in “indexed” form.
    public let attestation1: IndexedAttestation

    /// The first of the two slashable attestations. Note that this is in “indexed” form.
    public let attestation2: IndexedAttestation
}
