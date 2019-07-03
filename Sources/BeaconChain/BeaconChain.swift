import Foundation

struct BeaconChain {
    let genesisTime: UInt64
    let slot: Slot
    let fork: Fork
    let latestBlockHeader: BeaconBlockHeader
    let blockRoots: [Hash]
    let stateRoots: [Hash]
    let historicalRoots: [Hash]
    let eth1Data: Eth1Data
    let eth1DataVotes: [Eth1Data]
    let eth1DepositIndex: UInt64
    let validators: [Validator]
    let balances: [Gwei]
    let startShard: Shard
    let randaoMixes: [Hash]
    let activeIndexRoots: [Hash]
    let compactCommitteesRoots: [Hash]
    let slashings: [Gwei]
    let previousEpochAttestations: [PendingAttestation]
    let currentEpochAttestations: [PendingAttestation]
    let previousCrosslinks: [Crosslink]
    let currentCrosslinks: [Crosslink]
    let justificationBits: [Bool]
    let previousJustifiedCheckpoint: Checkpoint
    let currentJustifiedCheckpoint: Checkpoint
    let finalizedCheckpoint: Checkpoint
}
