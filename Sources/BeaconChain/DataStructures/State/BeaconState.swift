import Foundation

public class BeaconState {
    var slot: Int
    let genesisTime: TimeInterval
    let fork: Fork

    var validatorRegistry: [Validator]
    var validatorBalances: [Int] // @todo move balances into Validator class
    var validatorRegistryUpdateSlot: Int
    var validatorRegistryExitCount: Int
    var validatorRegistryDeltaChainTip: Data

    var latestRandaoMixes: [Data]
    let latestVdfOutputs: [Data]
    var previousEpochStartShard: Int
    var currentEpochStartShard: Int
    var previousEpochCalculationSlot: Int
    var currentEpochCalculationSlot: Int
    var previousEpochRandaoMix: Data
    var currentEpochRandaoMix: Data

//    let custodyChallenges: [CustodyChallenge] defined in 1.0

    var previousJustifiedSlot: Int
    var justifiedSlot: Int
    var justificationBitfield: Int
    var finalizedSlot: Int

    var latestCrosslinks: [Crosslink]
    var latestBlockRoots: [Data]
    var latestPenalizedBalances: [Int]
    var latestAttestations: [PendingAttestation]
    var batchedBlockRoots: [Data]

    var latestEth1Data: Eth1Data
    var eth1DataVotes: [Eth1DataVote]

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
