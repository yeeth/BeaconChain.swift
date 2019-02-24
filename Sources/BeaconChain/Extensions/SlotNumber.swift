import Foundation

extension SlotNumber {

    func toEpoch() -> EpochNumber {
        return self / SLOTS_PER_EPOCH
    }
}
