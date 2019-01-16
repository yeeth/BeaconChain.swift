import Foundation

class BeaconChain {

    // var state: BeaconState!! // @todo we may not need this here if we make the chain "stateless" and require the state to be passed with function calls

    func getInitialBeaconState(initialValidatorDeposits: [Deposit], genesisTime: TimeInterval, lastDepositRoot: Data) -> BeaconState {
        let state = BeaconChain.genesisState(genesisTime: genesisTime, lastDepositRoot: lastDepositRoot)

        for deposit in initialValidatorDeposits {
            BeaconChain.processDeposit(state: state, deposit: deposit)
        }

        for (i, _) in state.validatorRegistry.enumerated() {
            if (BeaconChain.getEffectiveBalance(state: state, index: i) >= MAX_DEPOSIT * GWEI_PER_ETH) {
                BeaconChain.activateValidator(state: state, index: i, genesis: true)
            }
        }

        return state
    }

    static func getEffectiveBalance(state: BeaconState, index: Int) -> Int {
        return min(state.validatorBalances[index], MAX_DEPOSIT * GWEI_PER_ETH)
    }

    static func getBlockRoot(state: BeaconState, slot: Int) -> Data {
        assert(state.slot <= slot + LATEST_BLOCK_ROOTS_LENGTH)
        assert(slot < state.slot)
        return state.latestBlockRoots[slot % LATEST_BLOCK_ROOTS_LENGTH]
    }

    static func getRandaoMix(state: BeaconState, slot: Int) -> Data {
        assert(state.slot <= slot + LATEST_RANDAO_MIXES_LENGTH)
        assert(slot < state.slot)
        return state.latestBlockRoots[slot % LATEST_RANDAO_MIXES_LENGTH]
    }

    static func getBeaconProposerIndex(state: BeaconState, slot: Int) -> Int {
        let (committee, _) = BeaconChain.getCrosslinkCommitteesAtSlot(state: state, slot: slot)[0]
        return committee[slot % committee.count]
    }

    static func getAttestationParticipants(state: BeaconState, data: AttestationData, participationBitfield: Int) -> [Int] {
        let committees = BeaconChain.getCrosslinkCommitteesAtSlot(state: state, slot: data.slot)
        for (_, (_, shard)) in committees.enumerated() {
            assert(shard == data.shard)
        }

        let crosslinkCommittee = committees.first(where: {
            $1 == data.shard
        })?.0

        var participants = [Int]()
        for (i, validatorIndex) in (crosslinkCommittee?.enumerated())! {
            let participationBit = (participationBitfield[i / 8] >> (7 - (i % 8))) % 2
            if participationBit == 1 {
                participants.append(validatorIndex)
            }
        }

        return participants
    }

    static func verifySlashableVoteData() -> Bool {

    }

    static func integerSquareRoot(n: Int) -> Int {
        assert(n >= 0)

        var x = n
        var y = (x + 1) / 2

        while y < x {
            x = y
            y = (x + n / x) / 2
        }

        return x
    }

    static func getForkVersion(data: ForkData, slot: Int) -> Int {
        if slot < data.forkSlot {
            return data.preForkVersion
        }

        return data.postForkVersion
    }

    static func getDomain(data: ForkData, slot: Int, domainType: Int) -> Int {
        return BeaconChain.getForkVersion(data: data, slot: slot) * 2^32 + domainType
    }

    static func isDoubleVote(first: AttestationData, second: AttestationData) -> Bool {
        return (first.slot / EPOCH_LENGTH) == (second.slot / EPOCH_LENGTH)
    }

    static func isSurroundVote(first: AttestationData, second: AttestationData) -> Bool {
        let firstSourceEpoch = first.justifiedSlot / EPOCH_LENGTH
        let secondSourceEpoch = second.justifiedSlot / EPOCH_LENGTH
        let firstTargetEpoch = first.slot / EPOCH_LENGTH
        let secondTargetEpoch = second.slot / EPOCH_LENGTH

        return firstSourceEpoch < secondSourceEpoch
            && secondSourceEpoch + 1 == secondTargetEpoch
            && secondTargetEpoch < firstTargetEpoch
    }

    static func verifySlashableVoteData(state: BeaconState, data: SlashableVoteData) -> Bool {
        if data.custodyBit0indices.count + data.custodyBit1indices.count > MAX_CASPER_VOTES {
            return false
        }

        return BLS.verify(
            pubkeys: [
                BLS.aggregate(pubkeys: data.custodyBit0indices.map({ (index: Int) in return state.validatorRegistry[index].pubkey })),
                BLS.aggregate(pubkeys: data.custodyBit1indices.map({ (index: Int) in return state.validatorRegistry[index].pubkey })),
            ],
            messages: [
                BeaconChain.hashTreeRoot(data: AttestationDataAndCustodyBit(data: data.data, custodyBit: false)),
                BeaconChain.hashTreeRoot(data: AttestationDataAndCustodyBit(data: data.data, custodyBit: true))
            ],
            signatures: data.aggregateSignature,
            domain: getDomain(data: state.forkData, slot: state.slot, domainType: DOMAIN_ATTESTATION)
        )
    }

    private static func genesisState(genesisTime: TimeInterval, lastDepositRoot: Data) -> BeaconState {
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

    static func processDeposit(state: BeaconState, deposit: Deposit) {
        assert(BeaconChain.validateProofOfPossession())

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

    static func validateProofOfPossession() -> Bool {
        // @todo
    }
}

extension BeaconChain {

    static func activateValidator(state: BeaconState, index: Int, genesis: Bool) {
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

    func penalizeValidator(state: BeaconState, index: Int) {
        exitValidator(state: state, index: index)

        state.latestPenalizedExitBalances[(state.slot / EPOCH_LENGTH) % LATEST_PENALIZED_EXIT_LENGTH] += BeaconChain.getEffectiveBalance(state: state, index: index)

        let whistleblowerIndex = BeaconChain.getBeaconProposerIndex(state: state, slot: state.slot)
        let whistleblowerReward = BeaconChain.getEffectiveBalance(state: state, index: index) / WHISTLEBLOWER_REWARD_QUOTIENT
        state.validatorBalances[whistleblowerIndex] += whistleblowerReward
        state.validatorBalances[index] -= whistleblowerReward
        state.validatorRegistry[index].penalizedSlot = state.slot
    }

    func prepareValidatorForWithdrawal(state: BeaconState, index: Int) {
        state.validatorRegistry[index].statusFlags |= WITHDRAWABLE
    }
}

extension BeaconChain {

    func updateValidatorRegistry(state: BeaconState) {
        let activeValidatorIndices = getActiveValidatorIndices(validators: state.validatorRegistry, slot: state.slot)

        let totalBalance = activeValidatorIndices.map({
            (i: Int) -> Int in
            return BeaconChain.getEffectiveBalance(state: state, index: i)
        }).reduce(0, +)

        let maxBalanceChurn = max(MAX_DEPOSIT * GWEI_PER_ETH, totalBalance / (2 * MAX_BALANCE_CHURN_QUOTIENT))

        var balanceChurn = 0
        for (i, validator) in state.validatorRegistry.enumerated() {
            if validator.activationSlot > state.slot + ENTRY_EXIT_DELAY && state.validatorBalances[i] >= MAX_DEPOSIT * GWEI_PER_ETH {
                balanceChurn += BeaconChain.getEffectiveBalance(state: state, index: i)
                if balanceChurn > maxBalanceChurn {
                    break
                }

                BeaconChain.activateValidator(state: state, index: i, genesis: false)
            }
        }

        balanceChurn = 0
        for (i, validator) in state.validatorRegistry.enumerated() {
            if validator.exitSlot > state.slot + ENTRY_EXIT_DELAY && (validator.statusFlags & INITIATED_EXIT) == 1 {
                balanceChurn += BeaconChain.getEffectiveBalance(state: state, index: i)
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
            if isActive(validator: validator, slot: slot) {
                return i
            }
        }
    }

    // @todo move these functions into validator record
    func isActive(validator: ValidatorRecord, slot: Int) -> Bool {
        return validator.activationSlot <= slot && slot < validator.exitSlot
    }
}

extension BeaconChain {

    func getCommitteeCountPerSlot(activeValidatorCount: Int) -> Int {
        return max(
            1,
            min(SHARD_COUNT / EPOCH_LENGTH, activeValidatorCount / EPOCH_LENGTH / TARGET_COMMITTEE_SIZE)
        )
    }

    func getPreviousEpochCommitteeCountPerSlot(state: BeaconState) -> Int {
        let validators = getActiveValidatorIndices(validators: state.validatorRegistry, slot: state.previousEpochCalculationSlot)
        return getCommitteeCountPerSlot(activeValidatorCount: validators.count)
    }

    func getCurrentEpochCommitteeCountPerSlot(state: BeaconState) -> Int {
        let validators = getActiveValidatorIndices(validators: state.validatorRegistry, slot: state.currentEpochCalculationSlot)
        return getCommitteeCountPerSlot(activeValidatorCount: validators.count)
    }

    // @todo return type here needs fixing
    static func getCrosslinkCommitteesAtSlot(state: BeaconState, slot: Int) -> [([Int], Int)] {
        // @todo
    }
}

extension BeaconChain {

    static func hash(data: Any) -> Data {

    }

    static func hashTreeRoot(data: Any) -> Data {

    }

}
