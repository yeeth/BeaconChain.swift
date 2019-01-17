import Foundation

class BeaconState {
    let slot: Int
    let genesisTime: TimeInterval
    let forkData: ForkData

    var validatorRegistry: [ValidatorRecord]
    var validatorBalances: [Int] // @todo move balances into Validator class
    var validatorRegistryLatestChangeSlot: Int
    var validatorRegistryExitCount: Int
    var validatorRegistryDeltaChainTip: Data

    let latestRandaoMixes: [Data]
    let latestVdfOutputs: [Data]
    let previousEpochStartShard: Int
    let currentEpochStartShard: Int
    let previousEpochCalculationSlot: Int
    let currentEpochCalculationSlot: Int
    let previousEpochRandaoMix: Data
    let currentEpochRandaoMix: Data

//    let custodyChallenges: [CustodyChallenge] defined in 1.0

    let previousJustifiedSlot: Int
    let justifiedSlot: Int
    let justificationBitfield: Int
    let finalizedSlot: Int

    let latestCrosslinks: [CrosslinkRecord]
    let latestBlockRoots: [Data]
    var latestPenalizedExitBalances: [Int]
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
        latestRandaoMixes: [Data],
        latestVdfOutputs: [Data],
        previousEpochStartShard: Int,
        currentEpochStartShard: Int,
        previousEpochCalculationSlot: Int,
        currentEpochCalculationSlot: Int,
        previousEpochRandaoMix: Data,
        currentEpochRandaoMix: Data,
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
