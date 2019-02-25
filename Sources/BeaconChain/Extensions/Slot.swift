import Foundation

extension Slot {

    func toEpoch() -> Epoch {
        return self / SLOTS_PER_EPOCH
    }
}
