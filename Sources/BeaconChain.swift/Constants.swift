import Foundation

let SHARD_COUNT = 2^10
let TARGET_COMMITTEE_SIZE = 2^7
let EJECTION_BALANCE = 2^4
let MAX_BALANCE_CHURN_QUOTIENT = 2^5
let GWEI_PER_ETH = 10^9
let BEACON_CHAIN_SHARD_NUMBER = 2^64 - 1
let MAX_CASPER_VOTES = 2^10
let LATEST_BLOCK_ROOTS_LENGTH = 2^13
let LATEST_RANDAO_MIXES_LENGTH = 2^13
let LATEST_PENALIZED_EXIT_LENGTH = 2^13
let MAX_WITHDRAWALS_PER_EPOCH = 2^2

let DEPOSIT_CONTRACT_TREE_DEPTH = 2^5
let MIN_DEPOSIT = 2^0
let MAX_DEPOSIT = 2^5

let GENESIS_FORK_VERSION = 0
let GENESIS_SLOT = 0
let GENESIS_START_SHARD = 0
let FAR_FUTURE_SLOT = 2^64 - 1
let ZERO_HASH = Data(repeating: 0, count: 32) // @todo unsure if this is bytes32(0x0)
let EMPTY_SIGNATURE = Data(repeating: 0, count: 48) // @todo unsure
let BLS_WITHDRAWAL_PREFIX_BYTE = 0x0

let SLOT_DURATION = 6
let MIN_ATTESTATION_INCLUSION_DELAY = 2^2
let EPOCH_LENGTH = 2^6
let SEED_LOOKAHEAD = 2^6
let ENTRY_EXIT_DELAY = 2^8
let DEPOSIT_ROOT_VOTING_PERIOD = 2^10
let MIN_VALIDATOR_WITHDRAWAL_TIME = 2^14

let BASE_REWARD_QUOTIENT = 2^10
let WHISTLEBLOWER_REWARD_QUOTIENT = 2^9
let INCLUDER_REWARD_QUOTIENT = 2^3
let INACTIVITY_PENALTY_QUOTIENT = 2^24

let INITIATED_EXIT = 2^0
let WITHDRAWABLE = 2^1

let MAX_PROPOSER_SLASHINGS = 2^4
let MAX_CASPER_SLASHINGS = 2^4
let MAX_ATTESTATIONS = 2^7
let MAX_DEPOSITS = 2^4
let MAX_EXITS = 2^4

let ACTIVATION = 0
let EXIT = 1
