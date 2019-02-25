import Foundation

extension Epoch {

    func startSlot() -> Slot {
        return self * SLOTS_PER_EPOCH
    }

    func entryExitEpoch() -> Epoch {
        return self + 1 + ACTIVATION_EXIT_DELAY
    }
}
