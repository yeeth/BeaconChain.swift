import Foundation

extension EpochNumber {


    func startSlot() -> SlotNumber {
        return self * EPOCH_LENGTH
    }

    func entryExitEpoch() -> EpochNumber {
        return self + 1 + ENTRY_EXIT_DELAY
    }

}
