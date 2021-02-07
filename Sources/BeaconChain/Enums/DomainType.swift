import Foundation

/// A signature domain type.
public enum DomainType: UInt32 {
    case beaconProposer, randao, attestation, deposit, voluntaryExit, transfer
}
