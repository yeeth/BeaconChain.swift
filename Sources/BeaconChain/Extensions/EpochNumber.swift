import Foundation

extension EpochNumber {

    func startSlot() -> SlotNumber {
        return self * SLOTS_PER_EPOCH
    }

    func entryExitEpoch() -> EpochNumber {
        return self + 1 + ACTIVATION_EXIT_DELAY
    }
}
