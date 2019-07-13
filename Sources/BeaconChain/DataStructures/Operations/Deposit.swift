import Foundation

/// Represents incoming validator deposits from the eth1 chain deposit contract.
public struct Deposit {

    /// The merkle proof against the BeaconState current Eth1Data.root
    public let proof: [Hash]

    /// The DepositData submit to the deposit contract to be verified using the proof against the deposit root.
    public let data: DepositData
}
