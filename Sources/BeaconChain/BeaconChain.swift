import Foundation

// @todo figure out better name
// @todo refactor so this isn't all in one class

class BeaconChain {

    static func hash(_ data: Any) -> Data {
        // @todo
        return Data(count: 0)
    }

    static func hashTreeRoot(_ data: Any) -> Data {
        // @todo
        return Data(count: 0)
    }

}

extension BeaconChain {

    static func getPreviousEpoch(state: BeaconState) -> EpochNumber {
        let currentEpoch = getCurrentEpoch(state: state)
        if currentEpoch == GENESIS_EPOCH {
            return GENESIS_EPOCH
        }

        return currentEpoch - 1
    }

    static func getCurrentEpoch(state: BeaconState) -> EpochNumber {
        return state.slot.toEpoch()
    }
}

extension BeaconChain {

    // @todo check this shit
    static func getPermutedIndex(index i: Int, listSize: Int, seed: Bytes32) -> Int {
        var index = i
        for round in 0..<SHUFFLE_ROUND_COUNT {
            var pointer = round
            let roundBytes = Data(bytes: &pointer, count: 1)
            let pivot = hash(seed + roundBytes)[0...8].withUnsafeBytes {
                (ptr: UnsafePointer<Int>) -> Int in
                return ptr.pointee
            } % listSize
            let flip = (pivot - index) % listSize
            let position = max(index, flip)

            var positionBytes = position / 256
            let source = hash(seed + roundBytes + Data(bytes: &positionBytes, count: 4))

            let byte = source[(position % 256) / 8]
            let bit = (byte >> (position % 8)) % UInt8(2)
            index = bit == 1 ? flip : index
        }

        return index
    }

    static func getShuffling(seed: Bytes32, validators: [Validator], epoch: EpochNumber) -> [[ValidatorIndex]] {
        let activeValidatorIndices = validators.activeIndices(epoch: epoch)
        let committeesPerEpoch = getEpochCommitteeCount(activeValidatorCount: validators.count)

        let shuffledActiveValidatorIndices = activeValidatorIndices.map {
            activeValidatorIndices[getPermutedIndex(index: Int($0), listSize: activeValidatorIndices.count, seed: seed)]
        }

        return shuffledActiveValidatorIndices.split(count: committeesPerEpoch)
    }
}

extension BeaconChain {

    static func getEpochCommitteeCount(activeValidatorCount: Int) -> Int {
        return Int(
            max(
                1,
                min(
                    SHARD_COUNT / EPOCH_LENGTH,
                    UInt64(activeValidatorCount) / EPOCH_LENGTH / TARGET_COMMITTEE_SIZE
                )
            ) * EPOCH_LENGTH
        )
    }

    static func getPreviousEpochCommitteeCount(state: BeaconState) -> Int {
        let previousActiveValidators = state.validatorRegistry.activeIndices(epoch: state.previousCalculationEpoch)
        return getEpochCommitteeCount(activeValidatorCount: previousActiveValidators.count)
    }

    static func getCurrentEpochCommitteeCount(state: BeaconState) -> Int {
        let currentActiveValidators = state.validatorRegistry.activeIndices(epoch: state.currentCalculationEpoch)
        return getEpochCommitteeCount(activeValidatorCount: currentActiveValidators.count)
    }

    static func getNextEpochCommitteeCount(state: BeaconState) -> Int {
        let nextActiveValidators = state.validatorRegistry.activeIndices(epoch: getCurrentEpoch(state: state) + 1)
        return getEpochCommitteeCount(activeValidatorCount: nextActiveValidators.count)
    }

    static func getCrosslinkCommitteesAtSlot(
        state: BeaconState,
        slot: SlotNumber,
        registryChange: Bool = false
    ) -> [([ValidatorIndex], ShardNumber)] {
        let epoch = slot.toEpoch()
        let currentEpoch = getCurrentEpoch(state: state)
        let previousEpoch = getPreviousEpoch(state: state)
        let nextEpoch = currentEpoch + 1

        assert(previousEpoch <= epoch && epoch <= nextEpoch)

        var committeesPerEpoch: Int!
        var seed: Data!
        var shufflingEpoch: UInt64!
        var shufflingStartShard: UInt64!

        if epoch == previousEpoch {
            committeesPerEpoch = getPreviousEpochCommitteeCount(state: state)
            seed = state.previousEpochSeed
            shufflingEpoch = state.previousCalculationEpoch
            shufflingStartShard = state.previousEpochStartShard
        } else if epoch == currentEpoch {
            committeesPerEpoch = getCurrentEpochCommitteeCount(state: state)
            seed = state.currentEpochSeed
            shufflingEpoch = state.currentCalculationEpoch
            shufflingStartShard = state.currentEpochStartShard
        } else if epoch == nextEpoch {
            let currentCommitteesPerEpoch = getCurrentEpochCommitteeCount(state: state)
            committeesPerEpoch = getNextEpochCommitteeCount(state: state)
            shufflingEpoch = nextEpoch
            let epochsSinceLastRegistryUpdate = currentEpoch - state.validatorRegistryUpdateEpoch
            if registryChange {
                seed = generateSeed(state: state, epoch: nextEpoch)
                shufflingStartShard = (state.currentEpochStartShard + UInt64(currentCommitteesPerEpoch)) % SHARD_COUNT
            } else if epochsSinceLastRegistryUpdate > 1 && isPowerOfTwo(Int(epochsSinceLastRegistryUpdate)) {
                seed = generateSeed(state: state, epoch: nextEpoch)
                shufflingStartShard = state.currentEpochStartShard
            } else {
                seed = state.currentEpochSeed
                shufflingStartShard = state.currentEpochStartShard
            }
        }

        let shuffling = getShuffling(seed: seed, validators: state.validatorRegistry, epoch: shufflingEpoch)

        let offset = slot % EPOCH_LENGTH
        let committeesPerSlot = UInt64(committeesPerEpoch) / EPOCH_LENGTH
        let slotStartShard = (shufflingStartShard + committeesPerSlot * offset) % SHARD_COUNT

        return (0..<committeesPerSlot).map {
            i in
            return (
                shuffling[Int(committeesPerSlot * offset + i)],
                (slotStartShard + i) % SHARD_COUNT
            )
        }
    }
}

extension BeaconChain {

    static func getBlockRoot(state: BeaconState, slot: SlotNumber) -> Bytes32 {
        assert(state.slot <= slot + LATEST_BLOCK_ROOTS_LENGTH)
        assert(slot < state.slot)
        return state.latestBlockRoots[Int(slot % LATEST_BLOCK_ROOTS_LENGTH)]
    }

    static func getRandaoMix(state: BeaconState, epoch: EpochNumber) -> Bytes32 {
        let currentEpoch = getCurrentEpoch(state: state)
        assert(currentEpoch - LATEST_RANDAO_MIXES_LENGTH < epoch && epoch <= currentEpoch)
        return state.latestRandaoMixes[Int(epoch % LATEST_RANDAO_MIXES_LENGTH)]
    }

    static func getActiveIndexRoot(state: BeaconState, epoch: EpochNumber) -> Bytes32 {
        let currentEpoch = getCurrentEpoch(state: state)
        assert(currentEpoch - LATEST_INDEX_ROOTS_LENGTH + ENTRY_EXIT_DELAY < epoch && epoch <= currentEpoch + ENTRY_EXIT_DELAY)
        return state.latestIndexRoots[Int(epoch % LATEST_INDEX_ROOTS_LENGTH)]
    }
}

extension BeaconChain {

    static func generateSeed(state: BeaconState, epoch: EpochNumber) -> Data {
        return hash(
            getRandaoMix(state: state, epoch: epoch - SEED_LOOKAHEAD) +
            getActiveIndexRoot(state: state, epoch: epoch) +
            epoch.bytes32
        )
    }

    static func getBeaconProposerIndex(state: BeaconState, slot: SlotNumber) -> ValidatorIndex {
        let (firstCommittee, _) = getCrosslinkCommitteesAtSlot(state: state, slot: slot)[0]
        return firstCommittee[Int(slot) % firstCommittee.count]
    }

    static func merkleRoot(values: [Bytes32]) -> Bytes32 {
        var o = [Data](repeating: Data(repeating: 0, count: 1), count: values.count - 1)
        o.append(contentsOf: values)

        for i in stride(from: values.count - 1, through: 0, by: -1) {
            o[i] = hash(o[i * 2] + o[i * 2 + 1])
        }

        return o[1]
    }

    static func getAttestationParticipants(
        state: BeaconState,
        attestationData: AttestationData,
        bitfield: Data
    ) -> [ValidatorIndex] {
        let crosslinkCommittees = getCrosslinkCommitteesAtSlot(state: state, slot: attestationData.slot)

        assert(crosslinkCommittees.map({ return $0.1 }).contains(attestationData.shard))

        // @todo clean this ugly up
        guard let crosslinkCommittee = crosslinkCommittees.first(where: {
            $0.1 == attestationData.shard
        })?.0 else {
            assert(false)
        }

        assert(verifyBitfield(bitfield: bitfield, committeeSize: crosslinkCommittee.count))

        return crosslinkCommittee.enumerated().compactMap {
            if getBitfieldBit(bitfield: bitfield, i: $0.offset) == 0b1 {
                return $0.element
            }

            return nil
        }
    }

    static func isPowerOfTwo(_ value: Int) -> Bool {
        if value == 0 {
            return false
        }

        return 2 ** Int(log2(Double(value))) == value
    }

    static func getEffectiveBalance(state: BeaconState, index: ValidatorIndex) -> Gwei {
        return min(state.validatorBalances[Int(index)], MAX_DEPOSIT_AMOUNT)
    }

    static func getForkVersion(fork: Fork, epoch: EpochNumber) -> UInt64 {
        if epoch < fork.epoch {
            return fork.previousVersion
        }

        return fork.currentVersion
    }

    static func getDomain(fork: Fork, epoch: EpochNumber, domainType: Domain) -> UInt64 {
        return getForkVersion(fork: fork, epoch: epoch) * 2 ** 32 + domainType.rawValue
    }

    static func getBitfieldBit(bitfield: Data, i: Int) -> Int {
        return Int((bitfield[i / 8] >> (7 - (i % 8))) % 2)
    }

    static func verifyBitfield(bitfield: Data, committeeSize: Int) -> Bool {
        if bitfield.count != (committeeSize + 7) / 8 {
            return false
        }

        for i in (committeeSize + 1)..<(bitfield.count * 8) {
            if getBitfieldBit(bitfield: bitfield, i: i) == 0b1 {
                return false
            }
        }

        return true
    }
}

extension BeaconChain {

    static func verifySlashableAttestation(state: BeaconState, slashableAttestation: SlashableAttestation) -> Bool {
        if slashableAttestation.custodyBitfield != Data(repeating: 0, count: slashableAttestation.custodyBitfield.count) {
            return false
        }

        if slashableAttestation.validatorIndices.count == 0 {
            return false
        }

        for i in 0..<(slashableAttestation.validatorIndices.count - 1) {
            if slashableAttestation.validatorIndices[i] >= slashableAttestation.validatorIndices[i + 1] {
                return false
            }
        }

        if !verifyBitfield(bitfield: slashableAttestation.custodyBitfield, committeeSize: slashableAttestation.validatorIndices.count) {
            return false
        }

        if slashableAttestation.validatorIndices.count > MAX_INDICES_PER_SLASHABLE_VOTE {
            return false
        }

        var custodyBit0Indices = [UInt64]()
        var custodyBit1Indices = [UInt64]()

        for (i, validatorIndex) in slashableAttestation.validatorIndices.enumerated() {
            if getBitfieldBit(bitfield: slashableAttestation.custodyBitfield, i: i) == 0b0 {
                custodyBit0Indices.append(validatorIndex)
            } else {
                custodyBit1Indices.append(validatorIndex)
            }
        }

        return BLS.verify(
            pubkeys: [
                BLS.aggregate(
                    pubkeys: custodyBit0Indices.map { (i) in
                        return state.validatorRegistry[Int(i)].pubkey
                    }
                ),
                BLS.aggregate(
                    pubkeys: custodyBit1Indices.map { (i) in
                        return state.validatorRegistry[Int(i)].pubkey
                    }
                )
            ],
            messages: [
                hashTreeRoot(AttestationDataAndCustodyBit(data: slashableAttestation.data, custodyBit: false)),
                hashTreeRoot(AttestationDataAndCustodyBit(data: slashableAttestation.data, custodyBit: true)),
            ],
            signature: slashableAttestation.aggregateSignature,
            domain: getDomain(fork: state.fork, epoch: slashableAttestation.data.slot.toEpoch(), domainType: Domain.ATTESTATION)
        )
    }

    static func isDoubleVote(_ left: AttestationData, _ right: AttestationData) -> Bool {
        return left.slot.toEpoch() == right.slot.toEpoch()
    }

    static func isSurroundVote(_ left: AttestationData, _ right: AttestationData) -> Bool {
        return left.justifiedEpoch < right.justifiedEpoch &&
            right.slot.toEpoch() < left.slot.toEpoch()
    }
}

extension BeaconChain {

    static func getInitialBeaconState(
        initialValidatorDeposits: [Deposit],
        genesisTime: UInt64,
        latestEth1Data: Eth1Data
    ) -> BeaconState {

        var state = genesisState(genesisTime: genesisTime, latestEth1Data: latestEth1Data)

        for deposit in initialValidatorDeposits {
            processDeposit(
                state: &state,
                pubkey: deposit.depositData.depositInput.pubkey,
                amount: deposit.depositData.amount,
                proofOfPossession: deposit.depositData.depositInput.proofOfPossession,
                withdrawalCredentials: deposit.depositData.depositInput.withdrawalCredentials
            )
        }

        for (i, _) in state.validatorRegistry.enumerated() {
            if getEffectiveBalance(state: state, index: ValidatorIndex(i)) >= MAX_DEPOSIT_AMOUNT {
                activateValidator(state: &state, index: ValidatorIndex(i), genesis: true)
            }
        }

        state.latestIndexRoots[Int(GENESIS_EPOCH % LATEST_INDEX_ROOTS_LENGTH)] = hashTreeRoot(
            state.validatorRegistry.activeIndices(epoch: GENESIS_EPOCH)
        )
        state.currentEpochSeed = generateSeed(state: state, epoch: GENESIS_EPOCH)

        return state
    }

    static func genesisState(genesisTime: UInt64, latestEth1Data: Eth1Data) -> BeaconState {
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
            latestRandaoMixes: [Data](repeating: ZERO_HASH, count: Int(LATEST_RANDAO_MIXES_LENGTH)),
            previousEpochStartShard: GENESIS_START_SHARD,
            currentEpochStartShard: GENESIS_START_SHARD,
            previousCalculationEpoch: GENESIS_EPOCH,
            currentCalculationEpoch: GENESIS_EPOCH,
            previousEpochSeed: ZERO_HASH,
            currentEpochSeed: ZERO_HASH,
            previousJustifiedEpoch: GENESIS_EPOCH,
            justifiedEpoch: GENESIS_EPOCH,
            justificationBitfield: 0,
            finalizedEpoch: GENESIS_EPOCH,
            latestCrosslinks: [Crosslink](repeating: Crosslink(epoch: GENESIS_EPOCH, shardBlockRoot: ZERO_HASH), count: Int(SHARD_COUNT)),
            latestBlockRoots: [Data](repeating: ZERO_HASH, count: Int(LATEST_BLOCK_ROOTS_LENGTH)),
            latestIndexRoots: [Data](repeating: ZERO_HASH, count: Int(LATEST_INDEX_ROOTS_LENGTH)),
            latestPenalizedBalances: [UInt64](repeating: 0, count: Int(LATEST_PENALIZED_EXIT_LENGTH)),
            latestAttestations: [PendingAttestation](),
            batchedBlockRoots: [Data](),
            latestEth1Data: latestEth1Data,
            eth1DataVotes: [Eth1DataVote]()
        )
    }
}

extension BeaconChain {

    static func validateProofOfPossesion(
        state: BeaconState,
        pubkey: BLSPubkey,
        proofOfPossession: BLSSignature,
        withdrawalCredentials: Bytes32
    ) -> Bool {
        let proofOfPossesionData = DepositInput(
            pubkey: pubkey,
            withdrawalCredentials: withdrawalCredentials,
            proofOfPossession: EMPTY_SIGNATURE
        )

        return BLS.verify(
            pubkey: pubkey,
            message: BeaconChain.hashTreeRoot(proofOfPossesionData),
            signature: proofOfPossession,
            domain: getDomain(fork: state.fork, epoch: getCurrentEpoch(state: state), domainType: Domain.DEPOSIT)
        )
    }

    static func processDeposit(
        state: inout BeaconState,
        pubkey: BLSPubkey,
        amount: Gwei,
        proofOfPossession: BLSSignature,
        withdrawalCredentials: Bytes32
    ) {
        assert(
            validateProofOfPossesion(
                state: state,
                pubkey: pubkey,
                proofOfPossession: proofOfPossession,
                withdrawalCredentials: withdrawalCredentials
            )
        )

        if let index = state.validatorRegistry.firstIndex(where: { $0.pubkey == pubkey }) {
            assert(state.validatorRegistry[index].withdrawalCredentials == withdrawalCredentials)
            state.validatorBalances[index] += amount
        } else {
            let validator = Validator(
                pubkey: pubkey,
                withdrawalCredentials: withdrawalCredentials,
                activationEpoch: FAR_FUTURE_EPOCH,
                exitEpoch: FAR_FUTURE_EPOCH,
                withdrawalEpoch: FAR_FUTURE_EPOCH,
                penalizedEpoch: FAR_FUTURE_EPOCH,
                statusFlags: 0
            )

            state.validatorRegistry.append(validator)
            state.validatorBalances.append(amount)
        }
    }
}

extension BeaconChain {

    static func activateValidator(state: inout BeaconState, index: ValidatorIndex, genesis: Bool) {
        state.validatorRegistry[Int(index)].activationEpoch = genesis ? GENESIS_EPOCH : getCurrentEpoch(state: state).entryExitEpoch()
    }

    static func initiateValidatorExit(state: inout BeaconState, index: ValidatorIndex) {
        state.validatorRegistry[Int(index)].statusFlags |= StatusFlag.INITIATED_EXIT.rawValue
    }

    static func exitValidator(state: inout BeaconState, index: ValidatorIndex) {
        var validator = state.validatorRegistry[Int(index)]
        if validator.exitEpoch <= getCurrentEpoch(state: state).entryExitEpoch() {
            return
        }

        validator.exitEpoch = getCurrentEpoch(state: state).entryExitEpoch()
        state.validatorRegistry[Int(index)] = validator
    }

    static func penalizeValidator(state: inout BeaconState, index: ValidatorIndex) {
        exitValidator(state: &state, index: index)

        state.latestPenalizedBalances[Int(getCurrentEpoch(state: state) % LATEST_PENALIZED_EXIT_LENGTH)] += getEffectiveBalance(state: state, index: index)

        let whistleblowerIndex = getBeaconProposerIndex(state: state, slot: state.slot)
        let whistleblowerReward = getEffectiveBalance(state: state, index: index) / WHISTLEBLOWER_REWARD_QUOTIENT

        state.validatorBalances[Int(whistleblowerIndex)] += whistleblowerReward
        state.validatorBalances[Int(index)] -= whistleblowerReward
        state.validatorRegistry[Int(index)].penalizedEpoch = getCurrentEpoch(state: state)
    }

    static func prepareValidatorForWithdrawal(state: inout BeaconState, index: ValidatorIndex) {
        state.validatorRegistry[Int(index)].statusFlags |= StatusFlag.WITHDRAWABLE.rawValue
    }
}
