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
