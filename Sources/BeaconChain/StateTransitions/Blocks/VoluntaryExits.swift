import Foundation

class VoluntaryExits: BlockTransitions {

    static func transition(state: inout BeaconState, block: BeaconBlock) {
        assert(block.body.voluntaryExits.count <= MAX_VOLUNTARY_EXITS)

        for exit in block.body.voluntaryExits {
            let validator = state.validatorRegistry[Int(exit.validatorIndex)]

            let epoch = BeaconChain.getCurrentEpoch(state: state)
            assert(validator.exitEpoch > epoch.delayedActivationExitEpoch())
            assert(epoch >= exit.epoch)

            assert(
                BLS.verify(
                    pubkey: validator.pubkey,
                    message: BeaconChain.signedRoot(exit, field: "signature"),
                    signature: exit.signature,
                    domain: state.fork.domain(epoch: exit.epoch, type: .exit)
                )
            )

            state.validatorRegistry[Int(exit.validatorIndex)].initiatedExit = true
        }
    }
}
