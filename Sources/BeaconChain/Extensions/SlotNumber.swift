import Foundation

extension SlotNumber {

    func toEpoch() -> EpochNumber {
        return self / EPOCH_LENGTH
    }

}