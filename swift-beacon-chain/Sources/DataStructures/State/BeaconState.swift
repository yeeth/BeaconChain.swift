//
//  BeaconState.swift
//  swift-beacon-chain
//
//  Created by Dean Eigenmann on 16.01.19.
//  Copyright © 2019 Dean Eigenmann. All rights reserved.
//

import Foundation

struct BeaconState {
    let slot: Int;
    let genesisTime: TimeInterval;
    let forkData: ForkData;

    let validatorRegistry: [ValidatorRecord];
    let validatorBalances: [Int];
    let validatorRegistryLatestChangeSlot: Int;
    let validatorRegistryExitCount: Int;
    let validatorRegistryDeltaChainTip: Data;

    let latestRandaoMixes: Data;
    let latestVdfOutputs: Data;
    let previousEpochStartShard: Int;
    let currentEpochStartShard: Int;
    let previousEpochCalculationSlot: Int;
    let currentEpochCalculationSlot: Int;
    let previousEpochRandaoMix: Int;
    let currentEpochRandaoMix: Int; // @todo do these need be data?

//    let custodyChallenges: [CustodyChallenge]; defined in 1.0

    let previousJustifiedSlot: uint64;
    let justifiedSlot: uint64;
    let justificationBitfield: uint64;
    let finalizedSlot: uint64;

    let latestCrosslinks: [CrosslinkRecord];
    let latestBlockRoots: [Data];
    let latestPenalizedExitBalances: [Int];
    let latestAttestations: [PendingAttestationRecord];
    let batchedBlockRoots: [Data];

    let latestDepositRoot: Data;
    let depositRootVotes: [DepositRootVote];
}
