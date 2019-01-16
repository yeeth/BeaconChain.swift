//
//  BeaconState.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 16.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

class BeaconState {
    let slot: Int
    let genesisTime: TimeInterval
    let forkData: ForkData

    var validatorRegistry: [ValidatorRecord]
    let validatorBalances: [Int]
    let validatorRegistryLatestChangeSlot: Int
    var validatorRegistryExitCount: Int
    let validatorRegistryDeltaChainTip: Data

    let latestRandaoMixes: Data
    let latestVdfOutputs: Data
    let previousEpochStartShard: Int
    let currentEpochStartShard: Int
    let previousEpochCalculationSlot: Int
    let currentEpochCalculationSlot: Int
    let previousEpochRandaoMix: Int
    let currentEpochRandaoMix: Int // @todo do these need be data?

//    let custodyChallenges: [CustodyChallenge] defined in 1.0

    let previousJustifiedSlot: Int
    let justifiedSlot: Int
    let justificationBitfield: Int
    let finalizedSlot: Int

    let latestCrosslinks: [CrosslinkRecord]
    let latestBlockRoots: [Data]
    let latestPenalizedExitBalances: [Int]
    let latestAttestations: [PendingAttestationRecord]
    let batchedBlockRoots: [Data]

    let latestDepositRoot: Data
    let depositRootVotes: [DepositRootVote]

    // @todo consider not passing those with default genesis values
    init(
        slot: Int,
        genesisTime: TimeInterval,
        forkData: ForkData,
        validatorRegistry: [ValidatorRecord],
        validatorBalances: [Int],
        validatorRegistryLatestChangeSlot: Int,
        validatorRegistryExitCount: Int,
        validatorRegistryDeltaChainTip: Data,
        latestRandaoMixes: Data,
        latestVdfOutputs: Data,
        previousEpochStartShard: Int,
        currentEpochStartShard: Int,
        previousEpochCalculationSlot: Int,
        currentEpochCalculationSlot: Int,
        previousEpochRandaoMix: Int,
        currentEpochRandaoMix: Int,
        previousJustifiedSlot: Int,
        justifiedSlot: Int,
        justificationBitfield: Int,
        finalizedSlot: Int,
        latestCrosslinks: [CrosslinkRecord],
        latestBlockRoots: [Data],
        latestPenalizedExitBalances: [Int],
        latestAttestations: [PendingAttestationRecord],
        batchedBlockRoots: [Data],
        latestDepositRoot: Data,
        depositRootVotes: [DepositRootVote]
    )
    {
        self.slot = slot
        self.genesisTime = genesisTime
        self.forkData = forkData
        self.validatorRegistry = validatorRegistry
        self.validatorBalances = validatorBalances
        self.validatorRegistryLatestChangeSlot = validatorRegistryLatestChangeSlot
        self.validatorRegistryExitCount = validatorRegistryExitCount
        self.validatorRegistryDeltaChainTip = validatorRegistryDeltaChainTip
        self.latestRandaoMixes = latestRandaoMixes
        self.latestVdfOutputs = latestVdfOutputs
        self.previousEpochStartShard = previousEpochStartShard
        self.currentEpochStartShard = currentEpochStartShard
        self.previousEpochCalculationSlot = previousEpochCalculationSlot
        self.currentEpochCalculationSlot = currentEpochCalculationSlot
        self.previousEpochRandaoMix = previousEpochRandaoMix
        self.currentEpochRandaoMix = currentEpochRandaoMix
        self.previousJustifiedSlot = previousJustifiedSlot
        self.justifiedSlot = justifiedSlot
        self.justificationBitfield = justificationBitfield
        self.finalizedSlot = finalizedSlot
        self.latestCrosslinks = latestCrosslinks
        self.latestBlockRoots = latestBlockRoots
        self.latestPenalizedExitBalances = latestPenalizedExitBalances
        self.latestAttestations = latestAttestations
        self.batchedBlockRoots = batchedBlockRoots
        self.latestDepositRoot = latestDepositRoot
        self.depositRootVotes = depositRootVotes
    }
}
