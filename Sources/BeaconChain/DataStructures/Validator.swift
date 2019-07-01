import Foundation

struct Validator {
    let pubkey: BLSPubkey
    let withdrawalCredentials: Data
    let effectiveBalance: Gwei
    var slashed: Bool
    let activationEligibilityEpoch: Epoch
    private(set) var activationEpoch: Epoch
    private(set) var exitEpoch: Epoch
    var withdrawableEpoch: Epoch

    func isActive(epoch: Epoch) -> Bool {
        return activationEpoch <= epoch && epoch < exitEpoch
    }

    func isSlashable(epoch: Epoch) -> Bool {
        return !slashed && (activationEpoch <= epoch && epoch < withdrawableEpoch)
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
