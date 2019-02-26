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

    static func signedRoot(_ data: Any, field: String) -> Data {
        // @todo
        return Data(count: 0)
    }

}

extension BeaconChain {

    static func getPreviousEpoch(state: BeaconState) -> Epoch {
        return max(getCurrentEpoch(state: state) - 1, GENESIS_EPOCH)
    }

    static func getCurrentEpoch(state: BeaconState) -> Epoch {
        return state.slot.toEpoch()
    }
}

extension BeaconChain {

    // @todo check this shit
    static func getPermutedIndex(index i: Int, listSize: Int, seed: Bytes32) -> Int {
        assert(i < listSize)
        assert(listSize < 2**40)

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

    static func getShuffling(seed: Bytes32, validators: [Validator], epoch: Epoch) -> [[ValidatorIndex]] {
        let activeValidatorIndices = validators.activeIndices(epoch: epoch)

        let shuffledActiveValidatorIndices = activeValidatorIndices.map {
            activeValidatorIndices[getPermutedIndex(index: Int($0), listSize: activeValidatorIndices.count, seed: seed)]
        }

        return shuffledActiveValidatorIndices.split(count: getEpochCommitteeCount(activeValidatorCount: activeValidatorIndices.count))
    }
}

extension BeaconChain {

    static func getEpochCommitteeCount(activeValidatorCount: Int) -> Int {
        return Int(
            max(
                1,
                min(
                    SHARD_COUNT / SLOTS_PER_EPOCH,
                    UInt64(activeValidatorCount) / SLOTS_PER_EPOCH / TARGET_COMMITTEE_SIZE
                )
            ) * SLOTS_PER_EPOCH
        )
    }

    static func getPreviousEpochCommitteeCount(state: BeaconState) -> Int {
        let previousActiveValidators = state.validatorRegistry.activeIndices(epoch: state.previousShufflingEpoch)
        return getEpochCommitteeCount(activeValidatorCount: previousActiveValidators.count)
    }

    static func getCurrentEpochCommitteeCount(state: BeaconState) -> Int {
        let currentActiveValidators = state.validatorRegistry.activeIndices(epoch: state.currentShufflingEpoch)
        return getEpochCommitteeCount(activeValidatorCount: currentActiveValidators.count)
    }

    static func getNextEpochCommitteeCount(state: BeaconState) -> Int {
        let nextActiveValidators = state.validatorRegistry.activeIndices(epoch: getCurrentEpoch(state: state) + 1)
        return getEpochCommitteeCount(activeValidatorCount: nextActiveValidators.count)
    }

    static func crosslinkCommittees(
        _ state: BeaconState,
        at slot: Slot,
        registryChange: Bool = false
    ) -> [([ValidatorIndex], Shard)] {
        let epoch = slot.toEpoch()
        let currentEpoch = getCurrentEpoch(state: state)
        let previousEpoch = getPreviousEpoch(state: state)
        let nextEpoch = currentEpoch + 1

        assert(previousEpoch <= epoch && epoch <= nextEpoch)

        var committeesPerEpoch: Int!
        var seed: Data!
        var shufflingEpoch: UInt64!
        var shufflingStartShard: UInt64!

        switch epoch {
        case currentEpoch:
            committeesPerEpoch = getCurrentEpochCommitteeCount(state: state)
            seed = state.currentShufflingSeed
            shufflingEpoch = state.currentShufflingEpoch
            shufflingStartShard = state.currentShufflingStartShard
        case previousEpoch:
            committeesPerEpoch = getPreviousEpochCommitteeCount(state: state)
            seed = state.previousShufflingSeed
            shufflingEpoch = state.previousShufflingEpoch
            shufflingStartShard = state.previousShufflingStartShard
        case nextEpoch:
            let currentCommitteesPerEpoch = getCurrentEpochCommitteeCount(state: state)
            committeesPerEpoch = getNextEpochCommitteeCount(state: state)
            shufflingEpoch = nextEpoch
            let epochsSinceLastRegistryUpdate = currentEpoch - state.validatorRegistryUpdateEpoch
            if registryChange {
                seed = generateSeed(state: state, epoch: nextEpoch)
                shufflingStartShard = (state.currentShufflingStartShard + UInt64(currentCommitteesPerEpoch)) % SHARD_COUNT
            } else if epochsSinceLastRegistryUpdate > 1 && Int(epochsSinceLastRegistryUpdate).isPowerOfTwo() {
                seed = generateSeed(state: state, epoch: nextEpoch)
                shufflingStartShard = state.currentShufflingStartShard
            } else {
                seed = state.currentShufflingSeed
                shufflingStartShard = state.currentShufflingStartShard
            }
        default:
            break
        }

        let shuffling = getShuffling(seed: seed, validators: state.validatorRegistry, epoch: shufflingEpoch)

        let offset = slot % SLOTS_PER_EPOCH
        let committeesPerSlot = UInt64(committeesPerEpoch) / SLOTS_PER_EPOCH
        let slotStartShard = (shufflingStartShard + committeesPerSlot * offset) % SHARD_COUNT

        return (0..<committeesPerSlot).map {
            return (
                shuffling[Int(committeesPerSlot * offset + $0)],
                (slotStartShard + $0) % SHARD_COUNT
            )
        }
    }
}

extension BeaconChain {

    static func getBlockRoot(state: BeaconState, slot: Slot) -> Bytes32 {
        assert(state.slot <= slot + LATEST_BLOCK_ROOTS_LENGTH)
        assert(slot < state.slot)
        return state.latestBlockRoots[Int(slot % LATEST_BLOCK_ROOTS_LENGTH)]
    }

    static func getRandaoMix(state: BeaconState, epoch: Epoch) -> Bytes32 {
        let currentEpoch = getCurrentEpoch(state: state)
        assert(currentEpoch - LATEST_RANDAO_MIXES_LENGTH < epoch && epoch <= currentEpoch)
        return state.latestRandaoMixes[Int(epoch % LATEST_RANDAO_MIXES_LENGTH)]
    }

    static func getActiveIndexRoot(state: BeaconState, epoch: Epoch) -> Bytes32 {
        let currentEpoch = getCurrentEpoch(state: state)
        assert(currentEpoch - LATEST_ACTIVE_INDEX_ROOTS_LENGTH + ACTIVATION_EXIT_DELAY < epoch && epoch <= currentEpoch + ACTIVATION_EXIT_DELAY)
        return state.latestActiveIndexRoots[Int(epoch % LATEST_ACTIVE_INDEX_ROOTS_LENGTH)]
    }
}

extension BeaconChain {

    static func generateSeed(state: BeaconState, epoch: Epoch) -> Data {
        return hash(
            getRandaoMix(state: state, epoch: epoch - MIN_SEED_LOOKAHEAD) +
            getActiveIndexRoot(state: state, epoch: epoch) +
            epoch.bytes32
        )
    }

    static func getBeaconProposerIndex(state: BeaconState, slot: Slot) -> ValidatorIndex {
        let firstCommittee = crosslinkCommittees(state, at: slot)[0].0
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
        let crosslinkCommittees = self.crosslinkCommittees(state, at: attestationData.slot)

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

    static func getEffectiveBalance(state: BeaconState, index: ValidatorIndex) -> Gwei {
        return min(state.validatorBalances[Int(index)], MAX_DEPOSIT_AMOUNT)
    }

    static func getBitfieldBit(bitfield: Data, i: Int) -> Int {
        return Int((bitfield[i / 8] >> (i % 8))) % 2
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
            domain: state.fork.domain(epoch: slashableAttestation.data.slot.toEpoch(), type: .ATTESTATION)
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
                activateValidator(state: &state, index: ValidatorIndex(i), genesis: true)
            }
        }

        let genesisActiveIndexRoot = hashTreeRoot(state.validatorRegistry.activeIndices(epoch: GENESIS_EPOCH))

        for i in 0..<LATEST_ACTIVE_INDEX_ROOTS_LENGTH {
            state.latestActiveIndexRoots[Int(i)] = genesisActiveIndexRoot
        }

        state.currentShufflingSeed = generateSeed(state: state, epoch: GENESIS_EPOCH)

        return state
    }

    static func genesisState(genesisTime: UInt64, latestEth1Data: Eth1Data, depositLength: Int) -> BeaconState {
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

extension BeaconChain {

    static func processDeposit(state: inout BeaconState, deposit: Deposit) {
        let depositInput = deposit.depositData.depositInput

        let proofIsValid = BLS.verify(
            pubkey: depositInput.pubkey,
            message: BeaconChain.signedRoot(depositInput, field: "proofOfPossession"),
            signature: depositInput.proofOfPossession,
            domain: state.fork.domain(epoch: BeaconChain.getCurrentEpoch(state: state), type: .DEPOSIT)
        )

        if !proofIsValid {
            return
        }

        let pubkey = depositInput.pubkey
        let amount = deposit.depositData.amount
        let withdrawalCredentials = depositInput.withdrawalCredentials

        if let index = state.validatorRegistry.firstIndex(where: { $0.pubkey == pubkey }) {
            assert(state.validatorRegistry[index].withdrawalCredentials == withdrawalCredentials)
            state.validatorBalances[index] += amount
        } else {
            let validator = Validator(
                pubkey: pubkey,
                withdrawalCredentials: withdrawalCredentials,
                activationEpoch: FAR_FUTURE_EPOCH,
                exitEpoch: FAR_FUTURE_EPOCH,
                withdrawableEpoch: FAR_FUTURE_EPOCH,
                initiatedExit: false,
                slashed: false
            )

            state.validatorRegistry.append(validator)
            state.validatorBalances.append(amount)
        }
    }
}

extension BeaconChain {

    static func activateValidator(state: inout BeaconState, index: ValidatorIndex, genesis: Bool) {
        state.validatorRegistry[Int(index)].activationEpoch = genesis ? GENESIS_EPOCH : getCurrentEpoch(state: state).delayedActivationExitEpoch()
    }

    static func initiateValidatorExit(state: inout BeaconState, index: ValidatorIndex) {
        state.validatorRegistry[Int(index)].initiatedExit = true
    }

    static func exitValidator(state: inout BeaconState, index: ValidatorIndex) {
        var validator = state.validatorRegistry[Int(index)]
        if validator.exitEpoch <= getCurrentEpoch(state: state).delayedActivationExitEpoch() {
            return
        }

        validator.exitEpoch = getCurrentEpoch(state: state).delayedActivationExitEpoch()
        state.validatorRegistry[Int(index)] = validator
    }

    static func slashValidator(state: inout BeaconState, index: ValidatorIndex) {
        assert(state.slot < state.validatorRegistry[Int(index)].withdrawableEpoch.startSlot())
        exitValidator(state: &state, index: index)

        state.latestSlashedBalances[Int(getCurrentEpoch(state: state) % LATEST_SLASHED_EXIT_LENGTH)] += getEffectiveBalance(state: state, index: index)

        let whistleblowerIndex = getBeaconProposerIndex(state: state, slot: state.slot)
        let whistleblowerReward = getEffectiveBalance(state: state, index: index) / WHISTLEBLOWER_REWARD_QUOTIENT

        state.validatorBalances[Int(whistleblowerIndex)] += whistleblowerReward
        state.validatorBalances[Int(index)] -= whistleblowerReward

        let currentEpoch = getCurrentEpoch(state: state)
        state.validatorRegistry[Int(index)].slashed = true
        state.validatorRegistry[Int(index)].withdrawableEpoch = currentEpoch + LATEST_SLASHED_EXIT_LENGTH
    }

    static func prepareValidatorForWithdrawal(state: inout BeaconState, index: ValidatorIndex) {
        state.validatorRegistry[Int(index)].withdrawableEpoch = getCurrentEpoch(state: state) + MIN_VALIDATOR_WITHDRAWABILITY_DELAY
    }
}
