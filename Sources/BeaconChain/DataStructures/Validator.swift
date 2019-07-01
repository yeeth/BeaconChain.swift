import Foundation

struct Validator {
    let pubkey: BLSPubkey
    let withdrawalCredentials: Data
    let effectiveBalance: Gwei
    var slashed: Bool
    let activationEligibilityEpoch: Epoch
    private(set) var activationEpoch: UInt64
    private(set) var exitEpoch: UInt64
    var withdrawableEpoch: UInt64

    func isActive(epoch: Epoch) -> Bool {
        return activationEpoch <= epoch && epoch < exitEpoch
    }

    // @todo passing state kinda seems ugly
    mutating func activate(state: BeaconState, genesis: Bool) {
        activationEpoch = genesis ? GENESIS_EPOCH : BeaconChain.getCurrentEpoch(state: state).delayedActivationExitEpoch()
    }

    mutating func exit(state: BeaconState) {
        if exitEpoch <= BeaconChain.getCurrentEpoch(state: state).delayedActivationExitEpoch() {
            return
        }

        exitEpoch = BeaconChain.getCurrentEpoch(state: state).delayedActivationExitEpoch()
    }

    mutating func prepareForWithdrawal(state: BeaconState) {
        withdrawableEpoch = BeaconChain.getCurrentEpoch(state: state) + MIN_VALIDATOR_WITHDRAWABILITY_DELAY
    }
}
