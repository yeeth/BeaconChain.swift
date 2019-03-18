import BeaconChain

class TestStore: Store {
    func parent(_ block: BeaconBlock) -> BeaconBlock {

    }

    func children(_ block: BeaconBlock) -> [BeaconBlock] {

    }

    func latestAttestation(validator: ValidatorIndex) -> Attestation {

    }

    func latestAttestationTarget(validator: ValidatorIndex) -> BeaconBlock {

    }
}
