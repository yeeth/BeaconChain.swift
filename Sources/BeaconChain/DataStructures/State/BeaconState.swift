import Foundation

// @todo sizes for types

struct BeaconState {
    let genesisTime: UInt64
    var slot: Slot
    let fork: Fork

    let latestBlockHeader: BeaconBlockHeader
    let blockRoots: [Data]
    let stateRoots: [Data]
    let historicalRoots: [Data]

    let eth1Data: Eth1Data
    let eth1DataVotes: [Eth1Data]
    let eth1DepositIndex: UInt64

    let validators: [Validator]
    let balances: [Gwei]

    let startShard: Shard
    let randaoMixes: [Data]
    let activeIndexRoots: [Data]
    let compactCommitteesRoots: [Data]

    let slashings: [Gwei]

    let previousEpochAttestations: [PendingAttestation]
    let currentEpochAttestations: [PendingAttestation]

    let previousCrosslinks: [Crosslink]
    let currentCrosslinks: [Crosslink]

    let justificationBits: [Bool] // @todo

    let previousJustifiedCheckpoint: Checkpoint
    let currentJustifiedCheckpoint: Checkpoint
    let finalizedCheckpoint: Checkpoint
}
