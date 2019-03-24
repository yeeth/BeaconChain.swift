import Foundation

public protocol Store {

    func parent(_ block: BeaconBlock) -> BeaconBlock
    func children(_ block: BeaconBlock) -> [BeaconBlock]
    func latestAttestation(validator: ValidatorIndex) -> Attestation
    func latestAttestationTarget(validator: ValidatorIndex) -> BeaconBlock
}

extension Store {

    func ancestor(block: BeaconBlock, slot: Slot) -> BeaconBlock? {
        if block.slot == slot {
            return block
        }

        if block.slot < slot {
            return nil
        }

        return ancestor(block: parent(block), slot: slot)
    }
}

