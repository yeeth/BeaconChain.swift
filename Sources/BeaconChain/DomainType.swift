import Foundation

/// A signature domain type
public enum DomainType: UInt64 {
    case beaconProposer, randao, attestation, deposit, voluntaryExit, transfer
}
