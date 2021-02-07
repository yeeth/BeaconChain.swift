import Foundation

struct Validator {
    let pubkey: Data
    let withdrawalCredentials: Data
    private(set) var activationEpoch: UInt64
    private(set) var exitEpoch: UInt64
    var withdrawableEpoch: UInt64
    var initiatedExit: Bool
    var slashed: Bool
    
    func isActive(epoch: Epoch) -> Bool {
        return activationEpoch <= epoch && epoch < exitEpoch
    }

    // @todo passing state kinda seems ugly
    mutating func activate(state: BeaconState, genesis: Bool) {
        activationEpoch = genesis ? InitialValues.GenesisEpoch : BeaconChain.getCurrentEpoch(state: state).delayedActivationExitEpoch()
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
