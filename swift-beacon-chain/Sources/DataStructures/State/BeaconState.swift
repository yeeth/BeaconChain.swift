//
//  BeaconState.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 16.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

class BeaconState {
    let slot: uint64;
    let genesisTime: uint64;
    let forkData: ForkData;

    let validatorRegistry: [ValidatorRecord];
    let validatorBalances: [uint64];
    let validatorRegistryLatestChangeSlot: uint64;
    let validatorRegistryExitCount: uint64;
    let validatorRegistryDeltaChainTip: Data;

    let latestRandaoMixes: Data;
    let latestVdfOutputs: Data;
    let previousEpochStartShard: uint64;
    let currentEpochStartShard: uint64;
    let previousEpochCalculationSlot: uint64;
    let currentEpochCalculationSlot: uint64;
    let previousEpochRandaoMix: uint64;
    let currentEpochRandaoMix: uint64;

//    let custodyChallenges: [CustodyChallenge]; defined in 1.0

    let previousJustifiedSlot: uint64;
    let justifiedSlot: uint64;
    let justificationBitfield: uint64;
    let finalizedSlot: uint64;

    let latestCrosslinks: [CrosslinkRecord];
    let latestBlockRoots: [Data];
    let latestPenalizedExitBalances: [uint64];
    let latestAttestations: [PendingAttestationRecord];
    let batchedBlockRoots: [Data];

    let latestDepositRoot: Data;
    let depositRootVotes: [DepositRootVote];
}
