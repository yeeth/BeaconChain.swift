import Foundation

class BeaconState {
    let slot: Int
    let genesisTime: TimeInterval
    let fork: Fork

    var validatorRegistry: [Validator]
    var validatorBalances: [Int] // @todo move balances into Validator class
    var validatorRegistryUpdateSlot: Int
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

    let latestCrosslinks: [Crosslink]
    let latestBlockRoots: [Data]
    var latestPenalizedBalances: [Int]
    let latestAttestations: [PendingAttestation]
    let batchedBlockRoots: [Data]

    let latestDepositRoot: Data
    let depositRootVotes: [DepositRootVote]

    // @todo consider not passing those with default genesis values
    init(
        slot: Int,
        genesisTime: TimeInterval,
        fork: Fork,
        validatorRegistry: [Validator],
        validatorBalances: [Int],
        validatorRegistryUpdateSlot: Int,
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
        latestCrosslinks: [Crosslink],
        latestBlockRoots: [Data],
        latestPenalizedBalances: [Int],
        latestAttestations: [PendingAttestation],
        batchedBlockRoots: [Data],
        latestDepositRoot: Data,
        depositRootVotes: [DepositRootVote]
    )
    {
        self.slot = slot
        self.genesisTime = genesisTime
        self.fork = fork
        self.validatorRegistry = validatorRegistry
        self.validatorBalances = validatorBalances
        self.validatorRegistryUpdateSlot = validatorRegistryUpdateSlot
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
        self.latestPenalizedBalances = latestPenalizedBalances
        self.latestAttestations = latestAttestations
        self.batchedBlockRoots = batchedBlockRoots
        self.latestDepositRoot = latestDepositRoot
        self.depositRootVotes = depositRootVotes
    }
}
