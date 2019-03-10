import Foundation

class StateFactory {

    static func createInitialBeaconState(
        genesisValidatorDeposits: [Deposit],
        genesisTime: UInt64,
        latestEth1Data: Eth1Data
    ) -> BeaconState {

        var state = genesisState(
            genesisTime: genesisTime,
            latestEth1Data: latestEth1Data,
            depositLength: genesisValidatorDeposits.count
        )

        for deposit in genesisValidatorDeposits {
            processDeposit(state: &state, deposit: deposit)
        }

        for (i, _) in state.validatorRegistry.enumerated() {
            if getEffectiveBalance(state: state, index: ValidatorIndex(i)) >= MAX_DEPOSIT_AMOUNT {
                state.validatorRegistry[i].activate(state: state, genesis: true)
            }
        }

        let genesisActiveIndexRoot = hashTreeRoot(state.validatorRegistry.activeIndices(epoch: GENESIS_EPOCH))

        for i in 0..<LATEST_ACTIVE_INDEX_ROOTS_LENGTH {
            state.latestActiveIndexRoots[Int(i)] = genesisActiveIndexRoot
        }

        state.currentShufflingSeed = generateSeed(state: state, epoch: GENESIS_EPOCH)

        return state
    }

    private static func genesisState(genesisTime: UInt64, latestEth1Data: Eth1Data, depositLength: Int) -> BeaconState {
        return BeaconState(
            slot: GENESIS_SLOT,
            genesisTime: genesisTime,
            fork: Fork(
                previousVersion: GENESIS_FORK_VERSION,
                currentVersion: GENESIS_FORK_VERSION,
                epoch: GENESIS_EPOCH
            ),
            validatorRegistry: [Validator](),
            validatorBalances: [UInt64](),
            validatorRegistryUpdateEpoch: GENESIS_EPOCH,
            latestRandaoMixes: [Data](repeating: EMPTY_SIGNATURE, count: Int(LATEST_RANDAO_MIXES_LENGTH)),
            previousShufflingStartShard: GENESIS_START_SHARD,
            currentShufflingStartShard: GENESIS_START_SHARD,
            previousShufflingEpoch: GENESIS_EPOCH,
            currentShufflingEpoch: GENESIS_EPOCH,
            previousShufflingSeed: ZERO_HASH,
            currentShufflingSeed: ZERO_HASH,
            previousJustifiedEpoch: GENESIS_EPOCH,
            justifiedEpoch: GENESIS_EPOCH,
            justificationBitfield: 0,
            finalizedEpoch: GENESIS_EPOCH,
            latestCrosslinks: [Crosslink](repeating: Crosslink(epoch: GENESIS_EPOCH, crosslinkDataRoot: ZERO_HASH), count: Int(SHARD_COUNT)),
            latestBlockRoots: [Data](repeating: ZERO_HASH, count: Int(LATEST_BLOCK_ROOTS_LENGTH)),
            latestActiveIndexRoots: [Data](repeating: ZERO_HASH, count: Int(LATEST_ACTIVE_INDEX_ROOTS_LENGTH)),
            latestSlashedBalances: [UInt64](repeating: 0, count: Int(LATEST_SLASHED_EXIT_LENGTH)),
            latestAttestations: [PendingAttestation](),
            batchedBlockRoots: [Data](),
            latestEth1Data: latestEth1Data,
            eth1DataVotes: [Eth1DataVote](),
            depositIndex: UInt64(depositLength)
        )
    }
}