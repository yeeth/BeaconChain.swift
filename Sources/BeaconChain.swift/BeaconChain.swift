import Foundation

class BeaconChain {

    // var state: BeaconState!! // @todo we may not need this here if we make the chain "stateless" and require the state to be passed with function calls

    func getInitialBeaconState(initialValidatorDeposits: [Deposit], genesisTime: TimeInterval, lastDepositRoot: Data) -> BeaconState {
        let state = genesisState(genesisTime: genesisTime, lastDepositRoot: lastDepositRoot)

        for deposit in initialValidatorDeposits {
            processDeposit(state: state, deposit: deposit)
        }

        for (i, _) in state.validatorRegistry.enumerated() {
            if (getEffectiveBalance(state: state, index: i) >= MAX_DEPOSIT * GWEI_PER_ETH) {
                activateValidator(state: state, index: i, genesis: true)
            }
        }

        return state
    }

    func getEffectiveBalance(state: BeaconState, index: Int) -> Int {
        return min(state.validatorBalances[index], MAX_DEPOSIT * GWEI_PER_ETH)
    }

    private func genesisState(genesisTime: TimeInterval, lastDepositRoot: Data) -> BeaconState {
        return BeaconState(
            slot: GENESIS_SLOT,
            genesisTime: genesisTime,
            forkData: ForkData(
                preForkVersion: GENESIS_FORK_VERSION,
                postForkVersion: GENESIS_FORK_VERSION,
                forkSlot: GENESIS_SLOT
            ),
            validatorRegistry: [ValidatorRecord](),
            validatorBalances: [Int](),
            validatorRegistryLatestChangeSlot: GENESIS_SLOT,
            validatorRegistryExitCount: 0,
            validatorRegistryDeltaChainTip: ZERO_HASH,
            latestRandaoMixes: [](), // @todo
            latestVdfOutputs: [](), // @todo
            previousEpochStartShard: GENESIS_START_SHARD,
            currentEpochStartShard: GENESIS_START_SHARD,
            previousEpochCalculationSlot: GENESIS_SLOT,
            currentEpochCalculationSlot: GENESIS_SLOT,
            previousEpochRandaoMix: ZERO_HASH,
            currentEpochRandaoMix: ZERO_HASH,
            previousJustifiedSlot: GENESIS_SLOT,
            justifiedSlot: GENESIS_SLOT,
            justificationBitfield: 0,
            finalizedSlot: GENESIS_SLOT,
            latestCrosslinks: [CrosslinkRecord(slot: GENESIS_SLOT, shardBlockRoot: ZERO_HASH)], // for _ in range(SHARD_COUNT)],
            latestBlockRoots: [ZERO_HASH], // [ZERO_HASH for _ in range(LATEST_BLOCK_ROOTS_LENGTH)],
            latestPenalizedExitBalances: [0], // #[0 for _ in range(LATEST_PENALIZED_EXIT_LENGTH)],
            latestAttestations: [Attestation](),
            batchedBlockRoots: [Data](),

            latestDepositRoot: lastDepositRoot,
            depositRootVotes: [DepositRootVote]()
        )
    }

}

extension BeaconChain {

    func processDeposit(state: BeaconState, deposit: Deposit) {
        assert(validateProofOfPossession())

        let pubkeys = state.validatorRegistry.enumerated().map{(_, validator: ValidatorRecord) in return validator.pubkey}

        if let index = pubkeys.firstIndex(of: deposit.depositData.depositInput.pubkey) {
            assert(state.validatorRegistry[index].withdrawalCredentials == deposit.depositData.depositInput.withdrawalCredentials)
            state.validatorBalances[index] += deposit.depositData.amount
            return
        }

        let validator = ValidatorRecord(
            pubkey: deposit.depositData.depositInput.pubkey,
            withdrawalCredentials: deposit.depositData.depositInput.withdrawalCredentials,
            randaoCommitment: deposit.depositData.depositInput.randaoCommitment,
            randaoLayers: 0,
            activationSlot: FAR_FUTURE_SLOT,
            exitSlot: FAR_FUTURE_SLOT,
            withdrawalSlot: FAR_FUTURE_SLOT,
            penalizedSlot: FAR_FUTURE_SLOT,
            exitCount: 0,
            statusFlags: 0,
            custodyCommitment: deposit.depositData.depositInput.custodyCommitment,
            latestCustodyReseedSlot: GENESIS_SLOT,
            penultimateCustodyReseedSlot: GENESIS_SLOT
        )

        state.validatorRegistry.append(validator)
        state.validatorBalances.append(deposit.depositData.amount)
    }

    func validateProofOfPossession() -> Bool {
        // @todo
    }
}

extension BeaconChain {

    func activateValidator(state: BeaconState, index: Int, genesis: Bool) {
        state.validatorRegistry[index].activationSlot = genesis ? GENESIS_SLOT : state.slot + ENTRY_EXIT_DELAY

        // @todo
    }

    func initiateValidatorExit(state: BeaconState, index: Int) {
        state.validatorRegistry[index].statusFlags |= INITIATED_EXIT
    }

    func exitValidator(state: BeaconState, index: Int) {
        if state.validatorRegistry[index].exitSlot <= state.slot + ENTRY_EXIT_DELAY {
            return
        }

        state.validatorRegistry[index].exitSlot = state.slot + ENTRY_EXIT_DELAY
        state.validatorRegistryExitCount += 1

        // @todo state.validator_registry_delta_chain_tip = hash_tree_root
    }
}

extension BeaconChain {

    func updateValidatorRegistry(state: BeaconState) {
        let activeValidatorIndices = getActiveValidatorIndices(validators: state.validatorRegistry, slot: state.slot)

        let totalBalance = activeValidatorIndices.map({
            (i: Int) -> Int in
            return getEffectiveBalance(state: state, index: i)
        }).reduce(0, +)

        let maxBalanceChurn = max(MAX_DEPOSIT * GWEI_PER_ETH, totalBalance / (2 * MAX_BALANCE_CHURN_QUOTIENT))

        var balanceChurn = 0
        for (i, validator) in state.validatorRegistry.enumerated() {
            if validator.activationSlot > state.slot + ENTRY_EXIT_DELAY && state.validatorBalances[i] >= MAX_DEPOSIT * GWEI_PER_ETH {
                balanceChurn += getEffectiveBalance(state: state, index: i)
                if balanceChurn > maxBalanceChurn {
                    break
                }

                activateValidator(state: state, index: i, genesis: false)
            }
        }

        balanceChurn = 0
        for (i, validator) in state.validatorRegistry.enumerated() {
            if validator.exitSlot > state.slot + ENTRY_EXIT_DELAY && (validator.statusFlags & INITIATED_EXIT) == 1 {
                balanceChurn += getEffectiveBalance(state: state, index: i)
                if balanceChurn > maxBalanceChurn {
                    break
                }

                exitValidator(state: state, index: i)
            }
        }

        state.validatorRegistryLatestChangeSlot = state.slot
    }

    func getActiveValidatorIndices(validators: [ValidatorRecord], slot: Int) -> [Int] {
        return validators.enumerated().compactMap{
            (arg) -> Int? in
            let (i, validator) = arg
            if isActiveValidator(validator: validator, slot: slot) {
                return i
            }
        }
    }

    // @todo move these functions into validator record
    func isActiveValidator(validator: ValidatorRecord, slot: Int) -> Bool {
        return validator.activationSlot <= slot && slot < validator.exitSlot
    }
}
