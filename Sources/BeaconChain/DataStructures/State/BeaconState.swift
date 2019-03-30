import Foundation

struct BeaconState {
    var slot: UInt64
    let genesisTime: UInt64
    let fork: Fork

    var validatorRegistry: [Validator]
    var validatorBalances: [UInt64]
    var validatorRegistryUpdateEpoch: UInt64

    var latestRandaoMixes: [Data]
    var previousShufflingStartShard: UInt64
    let currentShufflingStartShard: UInt64
    var previousShufflingEpoch: UInt64
    var currentShufflingEpoch: UInt64
    var previousShufflingSeed: Data
    var currentShufflingSeed: Data

    var previousEpochAttestations: [PendingAttestation]
    var currentEpochAttestations: [PendingAttestation]
    var previousJustifiedEpoch: UInt64
    var currentJustifiedEpoch: UInt64
    var previousJustifiedRoot: Data
    var currentJustifiedRoot: Data
    var justificationBitfield: UInt64
    var finalizedEpoch: UInt64
    var finalizedRoot: Data

    var latestCrosslinks: [Crosslink]
    var latestBlockRoots: [Data]
    var latestStateRoots: [Data]
    var latestActiveIndexRoots: [Data]
    var latestSlashedBalances: [UInt64]
    var latestBlockHeader: BeaconBlockHeader
    var historicalRoots: [Data]

    var latestEth1Data: Eth1Data
    var eth1DataVotes: [Eth1DataVote]
    var depositIndex: UInt64
}
