import Foundation

class BeaconChain {

    static func getInitialBeaconState(initialValidatorDeposits: [Deposit], genesisTime: TimeInterval, latestEth1Data: Eth1Data) -> BeaconState {
        let state = BeaconChain.genesisState(genesisTime: genesisTime, latestEth1Data: latestEth1Data)

        for deposit in initialValidatorDeposits {
            BeaconChain.processDeposit(state: state, deposit: deposit)
        }

        for (i, _) in state.validatorRegistry.enumerated() {
            if (BeaconChain.getEffectiveBalance(state: state, index: i) >= MAX_DEPOSIT_AMOUNT) {
                BeaconChain.activateValidator(state: state, index: i, genesis: true)
            }
        }

        return state
    }

    static func getEffectiveBalance(state: BeaconState, index: Int) -> Int {
        return min(state.validatorBalances[index], MAX_DEPOSIT_AMOUNT)
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

    static func getAttestationParticipants(state: BeaconState, data: AttestationData, aggregationBitfield: Data) -> [Int] {
        let committees = BeaconChain.getCrosslinkCommitteesAtSlot(state: state, slot: data.slot)
        for (_, (_, shard)) in committees.enumerated() {
            assert(shard == data.shard)
        }

        let crosslinkCommittee = committees.first(where: {
            $1 == data.shard
        })?.0

        var participants = [Int]()
        for (i, validatorIndex) in (crosslinkCommittee?.enumerated())! {
            let participationBit = (aggregationBitfield[i / 8] >> (7 - (i % 8))) % 2
            if participationBit == 1 {
                participants.append(validatorIndex)
            }
        }

        return participants
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

    static func getForkVersion(data: Fork, slot: Int) -> Int {
        if slot < data.slot {
            return data.previousVersion
        }

        return data.currentVersion
    }

    static func getDomain(data: Fork, slot: Int, domainType: Int) -> Int {
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
            domain: BeaconChain.getDomain(data: state.fork, slot: data.data.slot, domainType: DOMAIN_ATTESTATION)
        )
    }

    private static func genesisState(genesisTime: TimeInterval, latestEth1Data: Eth1Data) -> BeaconState {
        return BeaconState(
            slot: GENESIS_SLOT,
            genesisTime: genesisTime,
            fork: Fork(
                previousVersion: GENESIS_FORK_VERSION,
                currentVersion: GENESIS_FORK_VERSION,
                slot: GENESIS_SLOT
            ),
            validatorRegistry: [Validator](),
            validatorBalances: [Int](),
            validatorRegistryUpdateSlot: GENESIS_SLOT,
            validatorRegistryExitCount: 0,
            validatorRegistryDeltaChainTip: ZERO_HASH,
            latestRandaoMixes: [Data](repeating: ZERO_HASH, count: LATEST_RANDAO_MIXES_LENGTH),
            latestVdfOutputs: [Data](repeating: ZERO_HASH, count: LATEST_RANDAO_MIXES_LENGTH / EPOCH_LENGTH),
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
            latestCrosslinks: (0...SHARD_COUNT).map{ _ in return Crosslink(slot: GENESIS_SLOT, shardBlockRoot: ZERO_HASH) },
            latestBlockRoots: [Data](repeating: ZERO_HASH, count: LATEST_BLOCK_ROOTS_LENGTH),
            latestPenalizedBalances: [Int](repeating: 0, count: LATEST_PENALIZED_EXIT_LENGTH),
            latestAttestations: [PendingAttestation](),
            batchedBlockRoots: [Data](),

            latestEth1Data: latestEth1Data,
            eth1DataVotes: [Eth1DataVote]()
        )
    }

}

extension BeaconChain {

    static func processDeposit(state: BeaconState, deposit: Deposit) {
        assert(
            BeaconChain.validateProofOfPossession(
                state: state,
                pubkey: deposit.depositData.depositInput.pubkey,
                proof: deposit.depositData.depositInput.proofOfPossession,
                withdrawalCredentials: deposit.depositData.depositInput.withdrawalCredentials,
                randaoCommitment: deposit.depositData.depositInput.randaoCommitment,
                custodyCommitment: deposit.depositData.depositInput.custodyCommitment
            )
        )

        let pubkeys = state.validatorRegistry.enumerated().map{(_, validator: Validator) in return validator.pubkey}

        if let index = pubkeys.firstIndex(of: deposit.depositData.depositInput.pubkey) {
            assert(state.validatorRegistry[index].withdrawalCredentials == deposit.depositData.depositInput.withdrawalCredentials)
            state.validatorBalances[index] += deposit.depositData.amount
            return
        }

        let validator = Validator(
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

    static func validateProofOfPossession(state: BeaconState, pubkey: Data, proof: Data, withdrawalCredentials: Data, randaoCommitment: Data, custodyCommitment: Data) -> Bool {

        let input = DepositInput(
            pubkey: pubkey,
            withdrawalCredentials: withdrawalCredentials,
            randaoCommitment: randaoCommitment,
            custodyCommitment: custodyCommitment,
            proofOfPossession: EMPTY_SIGNATURE
        )

        return BLS.verify(
            pubkey: pubkey,
            message: hashTreeRoot(data: input),
            signature: proof,
            domain: BeaconChain.getDomain(data: state.fork, slot: state.slot, domainType: DOMAIN_DEPOSIT)
        )
    }

    static func processEjections(state: BeaconState) {
        for i in BeaconChain.getActiveValidatorIndices(validators: state.validatorRegistry, slot: state.slot) {
            if state.validatorBalances[i] < EJECTION_BALANCE {
                exitValidator(state: state, index: i)
            }
        }
    }
}

extension BeaconChain {

    static func activateValidator(state: BeaconState, index: Int, genesis: Bool) {
        state.validatorRegistry[index].activationSlot = genesis ? GENESIS_SLOT : state.slot + ENTRY_EXIT_DELAY

        let validator = state.validatorRegistry[index] // @todo change when validator is a class so we read earler
        state.validatorRegistryDeltaChainTip = hashTreeRoot(data: ValidatorRegistryDeltaBlock(
                lateRegistryDeltaRoot: state.validatorRegistryDeltaChainTip,
                validatorIndex: index,
                pubkey: validator.pubkey,
                slot: validator.activationSlot,
                flag: ACTIVATION
            )
        )
    }

    static func initiateValidatorExit(state: BeaconState, index: Int) {
        state.validatorRegistry[index].statusFlags |= INITIATED_EXIT
    }

    static func exitValidator(state: BeaconState, index: Int) {
        if state.validatorRegistry[index].exitSlot <= state.slot + ENTRY_EXIT_DELAY {
            return
        }

        state.validatorRegistry[index].exitSlot = state.slot + ENTRY_EXIT_DELAY
        state.validatorRegistryExitCount += 1

        let validator = state.validatorRegistry[index] // @todo change when validator is a class so we read earler
        state.validatorRegistryDeltaChainTip = hashTreeRoot(data: ValidatorRegistryDeltaBlock(
                lateRegistryDeltaRoot: state.validatorRegistryDeltaChainTip,
                validatorIndex: index,
                pubkey: validator.pubkey,
                slot: validator.exitSlot,
                flag: EXIT
            )
        )
    }

    static func penalizeValidator(state: BeaconState, index: Int) {
        BeaconChain.exitValidator(state: state, index: index)

        state.latestPenalizedBalances[(state.slot / EPOCH_LENGTH) % LATEST_PENALIZED_EXIT_LENGTH] += BeaconChain.getEffectiveBalance(state: state, index: index)

        let whistleblowerIndex = BeaconChain.getBeaconProposerIndex(state: state, slot: state.slot)
        let whistleblowerReward = BeaconChain.getEffectiveBalance(state: state, index: index) / WHISTLEBLOWER_REWARD_QUOTIENT
        state.validatorBalances[whistleblowerIndex] += whistleblowerReward
        state.validatorBalances[index] -= whistleblowerReward
        state.validatorRegistry[index].penalizedSlot = state.slot
    }

    static func prepareValidatorForWithdrawal(state: BeaconState, index: Int) {
        state.validatorRegistry[index].statusFlags |= WITHDRAWABLE
    }
}

extension BeaconChain {

    static func updateValidatorRegistry(state: BeaconState) {
        let activeValidatorIndices = BeaconChain.getActiveValidatorIndices(validators: state.validatorRegistry, slot: state.slot)

        let totalBalance = activeValidatorIndices.map({
            (i: Int) -> Int in
            return BeaconChain.getEffectiveBalance(state: state, index: i)
        }).reduce(0, +)

        let maxBalanceChurn = max(MAX_DEPOSIT_AMOUNT, totalBalance / (2 * MAX_BALANCE_CHURN_QUOTIENT))

        var balanceChurn = 0
        for (i, validator) in state.validatorRegistry.enumerated() {
            if validator.activationSlot > state.slot + ENTRY_EXIT_DELAY && state.validatorBalances[i] >= MAX_DEPOSIT_AMOUNT {
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

                BeaconChain.exitValidator(state: state, index: i)
            }
        }

        state.validatorRegistryUpdateSlot = state.slot
    }

    static func getActiveValidatorIndices(validators: [Validator], slot: Int) -> [Int] {
        return validators.enumerated().compactMap{
            (i, validator) -> Int? in
            if BeaconChain.isActive(validator: validator, slot: slot) {
                return i
            }

            return nil
        }
    }

    // @todo move these functions into validator 
    static func isActive(validator: Validator, slot: Int) -> Bool {
        return validator.activationSlot <= slot && slot < validator.exitSlot
    }
}

extension BeaconChain {

    static func getCommitteeCountPerSlot(activeValidatorCount: Int) -> Int {
        return max(
            1,
            min(SHARD_COUNT / EPOCH_LENGTH, activeValidatorCount / EPOCH_LENGTH / TARGET_COMMITTEE_SIZE)
        )
    }

    static func getPreviousEpochCommitteeCountPerSlot(state: BeaconState) -> Int {
        let validators = BeaconChain.getActiveValidatorIndices(
            validators: state.validatorRegistry,
            slot: state.previousEpochCalculationSlot
        )

        return BeaconChain.getCommitteeCountPerSlot(activeValidatorCount: validators.count)
    }

    static func getCurrentEpochCommitteeCountPerSlot(state: BeaconState) -> Int {
        let validators = BeaconChain.getActiveValidatorIndices(
            validators: state.validatorRegistry,
            slot: state.currentEpochCalculationSlot
        )

        return BeaconChain.getCommitteeCountPerSlot(activeValidatorCount: validators.count)
    }

    // @todo rthis is probably broken
    static func getCrosslinkCommitteesAtSlot(state: BeaconState, slot: Int) -> [([Int], Int)] {
        let earliestSlot = state.slot - (state.slot % EPOCH_LENGTH) - EPOCH_LENGTH
        assert(earliestSlot <= slot && slot < earliestSlot + (EPOCH_LENGTH * 2))
        let offest = slot % EPOCH_LENGTH

        var committeesPerSlot: Int
        var shuffling: [[Int]]
        var slotStartShard: Int
        if slot < earliestSlot + EPOCH_LENGTH {
            committeesPerSlot = BeaconChain.getPreviousEpochCommitteeCountPerSlot(state: state)
            shuffling = getShuffling(
                seed: state.previousEpochRandaoMix,
                validators: state.validatorRegistry, slot: state.previousEpochCalculationSlot
            );
            slotStartShard = (state.previousEpochStartShard + (committeesPerSlot * offest)) % SHARD_COUNT
        } else {
            committeesPerSlot = BeaconChain.getCurrentEpochCommitteeCountPerSlot(state: state)
            shuffling = getShuffling(
                seed: state.currentEpochRandaoMix,
                validators: state.validatorRegistry, slot: state.currentEpochCalculationSlot
            );
            slotStartShard = (state.currentEpochStartShard + (committeesPerSlot * offest)) % SHARD_COUNT
        }

        return stride(from: 0, to: committeesPerSlot, by: 1).map {
            (i: Int) -> ([Int], Int) in
            return (shuffling[committeesPerSlot * (offest + i)], (slotStartShard + i) % SHARD_COUNT)
        }
    }
}

extension BeaconChain {

    static func merkleRoot(values: [Data]) -> Data {
        var o = [Data](repeating: Data(repeating: 0, count: 1), count: values.count - 1)
        o.append(contentsOf: values)

        for i in stride(from: values.count - 1, through: 0, by: -1) {
            o[i] = hash(data: o[i * 2] + o[i * 2 + 1])
        }

        return o[1]
    }

    static func hash(data: Any) -> Data {
        return Data(repeating: 0, count: 32) // @todo
    }

    static func hashTreeRoot(data: Any) -> Data {
        return Data(repeating: 0, count: 32) // @todo
    }

}

extension BeaconChain {

    // @todo make this an extenstion to arrays
    static func shuffle<T>(values: [T], seed: Data) -> [T] {
        let randBytes = 3
        let randMax = 2^(randBytes * 8) - 1

        assert(values.count < randMax)

        var output = values
        var source = seed

        var index = 0
        while index < values.count - 1 {
            source = BeaconChain.hash(data: source)

            for i in stride(from: 0, through: 32 - (32 % randBytes), by: randBytes) {
                let remaining = values.count - index
                if remaining == 1 {
                    break
                }

                let sampleFromSource = source.subdata(in: Range(i...(i + randBytes))).withUnsafeBytes {
                    (ptr: UnsafePointer<Int>) -> Int in
                    return ptr.pointee
                }

                let sampleMax = randMax - randMax % remaining

                if sampleFromSource < sampleMax {
                    let replacementPosition = (sampleFromSource % remaining) + index
                    (output[index], output[replacementPosition]) = (output[replacementPosition], output[index])
                    index += 1
                }
            }
        }

        return output
    }

    // @todo make this an extenstion to arrays
    static func split<T>(values: [T], count: Int) -> [[T]] {
        return stride(from: 0, to: values.count, by: count).map {
            Array(values[$0 ..< min($0 + count, values.count)])
        }
    }

    static func getShuffling(seed: Data, validators: [Validator], slot: Int) -> [[Int]] {
        var slot = slot - (slot % EPOCH_LENGTH)

        let activeValidatorIndices = getActiveValidatorIndices(validators: validators, slot: slot)
        let committeesPerSlot = BeaconChain.getCommitteeCountPerSlot(activeValidatorCount: activeValidatorIndices.count)

        let shuffledValidatorIndices = shuffle(
            values: activeValidatorIndices,
            seed: (seed ^ Data(bytes: &slot, count: MemoryLayout.size(ofValue: slot)))
        )

        return split(values: shuffledValidatorIndices, count: committeesPerSlot * EPOCH_LENGTH)
    }
}
