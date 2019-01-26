import Foundation

class BeaconState {
    var slot: UInt64
    let genesisTime: TimeInterval
    let fork: Fork

    var validatorRegistry: [Validator]
    var validatorBalances: [UInt64] // @todo move balances into Validator class
    var validatorRegistryUpdateSlot: UInt64
    var validatorRegistryExitCount: UInt64
    var validatorRegistryDeltaChainTip: Data

    var latestRandaoMixes: [Data]
    let latestVdfOutputs: [Data]
    var previousEpochStartShard: UInt64
    var currentEpochStartShard: UInt64
    var previousEpochCalculationSlot: UInt64
    var currentEpochCalculationSlot: UInt64
    var previousEpochRandaoMix: Data
    var currentEpochRandaoMix: Data

//    let custodyChallenges: [CustodyChallenge] defined in 1.0

    var previousJustifiedSlot: UInt64
    var justifiedSlot: UInt64
    var justificationBitfield: UInt64
    var finalizedSlot: UInt64

    var latestCrosslinks: [Crosslink]
    var latestBlockRoots: [Data]
    var latestPenalizedBalances: [UInt64]
    var latestAttestations: [PendingAttestation]
    var batchedBlockRoots: [Data]

    var latestEth1Data: Eth1Data
    var eth1DataVotes: [Eth1DataVote]

    // @todo consider not passing those with default genesis values
    init(
        slot: UInt64,
        genesisTime: TimeInterval,
        fork: Fork,
        validatorRegistry: [Validator],
        validatorBalances: [UInt64],
        validatorRegistryUpdateSlot: UInt64,
        validatorRegistryExitCount: UInt64,
        validatorRegistryDeltaChainTip: Data,
        latestRandaoMixes: [Data],
        latestVdfOutputs: [Data],
        previousEpochStartShard: UInt64,
        currentEpochStartShard: UInt64,
        previousEpochCalculationSlot: UInt64,
        currentEpochCalculationSlot: UInt64,
        previousEpochRandaoMix: Data,
        currentEpochRandaoMix: Data,
        previousJustifiedSlot: UInt64,
        justifiedSlot: UInt64,
        justificationBitfield: UInt64,
        finalizedSlot: UInt64,
        latestCrosslinks: [Crosslink],
        latestBlockRoots: [Data],
        latestPenalizedBalances: [UInt64],
        latestAttestations: [PendingAttestation],
        batchedBlockRoots: [Data],
        latestEth1Data: Eth1Data,
        eth1DataVotes: [Eth1DataVote]
    ) {
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
        self.latestEth1Data = latestEth1Data
        self.eth1DataVotes = eth1DataVotes
    }
}
