import Foundation

// @todo figure out better name

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

    // @todo should be a function on slot number types
    static func slotToEpoch(_ slot: SlotNumber) -> EpochNumber {
        return slot / EPOCH_LENGTH
    }

    static func getCurrentEpoch(state: BeaconState) -> EpochNumber {
        return slotToEpoch(state.slot)
    }

    static func getEpochStartSlot(_ epoch: EpochNumber) -> SlotNumber {
        return epoch * EPOCH_LENGTH
    }
}

extension BeaconChain {

    static func isActive(validator: Validator, epoch: EpochNumber) -> Bool {
        return validator.activationEpoch <= epoch && epoch < validator.exitEpoch
    }

    static func getActiveValidatorIndices(validators: [Validator], epoch: EpochNumber) -> [ValidatorIndex] {
        return validators.enumerated().compactMap {
            (k, v) in
            if isActive(validator: v, epoch: epoch) {
                return ValidatorIndex(k)
            }

            return nil
        }
    }
}

extension BeaconChain {

    // @todo use generic instead of any
    static func shuffle<T>(values: [T], seed: Bytes32) -> [T] {
        return [T]()
    }

    static func split<T>(values: [T], splitCount: Int) -> [[T]] {
        return [[T]]()
    }

    static func getShuffling(seed: Bytes32, validators: [Validator], epoch: EpochNumber) -> [[ValidatorIndex]] {
        let activeValidatorIndices = getActiveValidatorIndices(validators: validators, epoch: epoch)
        let committeesPerEpoch = getEpochCommitteeCount(activeValidatorCount: validators.count)

        var e = epoch
        let newSeed = seed ^ Data(bytes: &e, count: 32)
        let shuffledActiveValidatorIndices = shuffle(values: activeValidatorIndices, seed: newSeed)

        return split(values: shuffledActiveValidatorIndices, splitCount: committeesPerEpoch)
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
        let previousActiveValidators = getActiveValidatorIndices(
            validators: state.validatorRegistry,
            epoch: state.previousCalculationEpoch
        )

        return getEpochCommitteeCount(activeValidatorCount: previousActiveValidators.count)
    }

    static func getCurrentEpochCommitteeCount(state: BeaconState) -> Int {
        let currentActiveValidators = getActiveValidatorIndices(
            validators: state.validatorRegistry,
            epoch: state.currentCalculationEpoch
        )

        return getEpochCommitteeCount(activeValidatorCount: currentActiveValidators.count)
    }

    static func getCrosslinkCommitteesAtSlot(state: BeaconState, slot: SlotNumber) -> [([ValidatorIndex], ShardNumber)] {
        let epoch = slotToEpoch(slot)
        let currentEpoch = getCurrentEpoch(state: state)
        let previousEpoch = currentEpoch > GENESIS_EPOCH ? currentEpoch - 1 : currentEpoch
        let nextEpoch = currentEpoch + 1

        assert(previousEpoch <= epoch && epoch < nextEpoch)

        var committeesPerEpoch: Int
        var seed: Data
        var shufflingEpoch: UInt64
        var shufflingStartShard: UInt64
        if epoch < currentEpoch {
            committeesPerEpoch = getPreviousEpochCommitteeCount(state: state)
            seed = state.previousEpochSeed
            shufflingEpoch = state.previousCalculationEpoch
            shufflingStartShard = state.previousEpochStartShard
        } else {
            committeesPerEpoch = getCurrentEpochCommitteeCount(state: state)
            seed = state.currentEpochSeed
            shufflingEpoch = state.currentCalculationEpoch
            shufflingStartShard = state.currentEpochStartShard
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
        assert(currentEpoch - LATEST_INDEX_ROOTS_LENGTH < epoch && epoch <= currentEpoch)
        return state.latestIndexRoots[Int(epoch % LATEST_INDEX_ROOTS_LENGTH)]
    }
}

extension BeaconChain {

    static func generateSeed(state: BeaconState, epoch: EpochNumber) -> Data {
        return hash(
            getRandaoMix(state: state, epoch: epoch - SEED_LOOKAHEAD) + getActiveIndexRoot(state: state, epoch: epoch)
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
        aggregationBitfield: Data
    ) -> [ValidatorIndex] {
        let crosslinkCommittees = getCrosslinkCommitteesAtSlot(state: state, slot: attestationData.slot)

        assert(crosslinkCommittees.map({return $0.1 }).contains(attestationData.shard))

        // @todo clean this ugly up
        guard let crosslinkCommittee = crosslinkCommittees.first(where: {
            $0.1 == attestationData.shard
        })?.0 else {
            assert(false)
        }

        assert(aggregationBitfield.count == (crosslinkCommittee.count + 7) / 8)

        return crosslinkCommittee.enumerated().compactMap {
            let i = $0.offset
            if aggregationBitfield[i / 8] >> (7 - (i % 8)) % 2 == 1 {
                return $0.element
            }

            return nil
        }
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
        return getForkVersion(fork: fork, epoch: epoch) * 2**32 + domainType.rawValue
    }
}

extension BeaconChain {

    static func verifySlashableVoteData(state: BeaconState, data: SlashableVoteData) -> Bool {
        if data.custodyBit0Indices.count + data.custodyBit1Indices.count > MAX_CASPER_VOTES {
            return false
        }

        return BLS.verify(
            pubkeys: [
                BLS.aggregate(
                    pubkeys: data.custodyBit0Indices.map { (i) in return state.validatorRegistry[Int(i)].pubkey }
                ),
                BLS.aggregate(
                    pubkeys: data.custodyBit1Indices.map { (i) in return state.validatorRegistry[Int(i)].pubkey }
                )
            ],
            messages: [
                hashTreeRoot(AttestationDataAndCustodyBit(data: data.data, custodyBit: false)),
                hashTreeRoot(AttestationDataAndCustodyBit(data: data.data, custodyBit: true)),
            ],
            signature: data.aggregateSignature,
            domain: getDomain(fork: state.fork, epoch: slotToEpoch(data.data.slot), domainType: Domain.ATTESTATION)
        )
    }

    static func isDoubleVote(_ left: AttestationData, _ right: AttestationData) -> Bool {
        return slotToEpoch(left.slot) == slotToEpoch(right.slot)
    }

    static func isSurroundVote(_ left: AttestationData, _ right: AttestationData) -> Bool {
        return left.justifiedEpoch < right.justifiedEpoch &&
            right.justifiedEpoch + 1 == slotToEpoch(right.slot) &&
            slotToEpoch(right.slot) < slotToEpoch(left.slot)
    }
}
