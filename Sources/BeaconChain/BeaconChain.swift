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
