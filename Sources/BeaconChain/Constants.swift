import Foundation

// Misc
let SHARD_COUNT = UInt64(2**10)
let TARGET_COMMITTEE_SIZE = UInt64(2**7)
let MAX_BALANCE_CHURN_QUOTIENT = UInt64(2**5)
let BEACON_CHAIN_SHARD_NUMBER = UInt64.max
let MAX_INDICES_PER_SLASHABLE_VOTE = UInt64(2**12)
let MAX_EXIT_DEQUEUES_PER_EPOCH = UInt64(2**2)
let SHUFFLE_ROUND_COUNT = 90

// Deposit Contract
//let DEPOSIT_CONTRACT_ADDRESS =
let DEPOSIT_CONTRACT_TREE_DEPTH = UInt64(2**5)



// MARK: GWEI Values

struct GWEIValues {
    
    static let MinDepositAmount = UInt64(2**0 * UInt64(1e9))
    static let MaxDepositAmount = UInt64(2**5 * UInt64(1e9))
    static let ForkChoiceBalanceIncremement = UInt64(2**0 * UInt64(1e9))
    static let EjectionBalance = UInt64(2**4 * UInt64(1e9))
}

// MARK: Initial Values

struct InitialValues {
    
    static let GenesisForkVersion = UInt64(0)
    static let GenesisSlot = UInt64(2**32)
    static let GenesisEpoch = Slot(GenesisSlot).toEpoch()
    static let GenesisStartShard = UInt64(0)
    static let FarFutureEpoch = UInt64.max
    static let ZeroHash = Data(repeating: 0, count: 32) // @todo create type
    static let EmptySignature = Data(repeating: 0, count: 96)
    static let BLSWithdrawalPrefixByte = Data(repeating: 0, count: 1)
}

// Time parameters
let SECONDS_PER_SLOT = UInt64(6)
let MIN_ATTESTATION_INCLUSION_DELAY = UInt64(2**2)
let SLOTS_PER_EPOCH = UInt64(2**6)
let MIN_SEED_LOOKAHEAD = UInt64(2**0)
let ACTIVATION_EXIT_DELAY = UInt64(2**2)
let EPOCHS_PER_ETH1_VOTING_PERIOD = UInt64(2**4)
let MIN_VALIDATOR_WITHDRAWABILITY_DELAY = UInt64(2**8)

// State list lengths
let LATEST_BLOCK_ROOTS_LENGTH = UInt64(2**13)
let LATEST_RANDAO_MIXES_LENGTH = UInt64(2**13)
let LATEST_ACTIVE_INDEX_ROOTS_LENGTH = UInt64(2**13)
let LATEST_SLASHED_EXIT_LENGTH = UInt64(2**13)

// Reward and penalty quotients
let BASE_REWARD_QUOTIENT = UInt64(2**5)
let WHISTLEBLOWER_REWARD_QUOTIENT = UInt64(2**9)
let ATTESTATION_INCLUSION_REWARD_QUOTIENT = UInt64(2**3)
let INACTIVITY_PENALTY_QUOTIENT = UInt64(2**24)
let MIN_PENALTY_QUOTIENT = UInt64(2**5)

// Max transactions per block
let MAX_PROPOSER_SLASHINGS = UInt64(2**4)
let MAX_ATTESTER_SLASHINGS = UInt64(2**0)
let MAX_ATTESTATIONS = UInt64(2**7)
let MAX_DEPOSITS = UInt64(2**4)
let MAX_VOLUNTARY_EXITS = UInt64(2**4)
let MAX_TRANSFERS = UInt64(2**4)
