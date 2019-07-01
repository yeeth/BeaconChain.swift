import Foundation

// @todo sizes for types

struct BeaconState {
    let genesisTime: UInt64
    var slot: Slot
    let fork: Fork

    let latestBlockHeader: BeaconBlockHeader
    let blockRoots: [Data]
    let stateRoots: [Data]
    let historicalRoots: [Data]

    let eth1Data: Eth1Data
    let eth1DataVotes: [Eth1Data]
    let eth1DepositIndex: UInt64

    private(set) var validators: [Validator]
    private(set) var balances: [Gwei]

    let startShard: Shard
    let randaoMixes: [Data]
    let activeIndexRoots: [Data]
    let compactCommitteesRoots: [Data]

    private(set) var slashings: [Gwei]

    let previousEpochAttestations: [PendingAttestation]
    let currentEpochAttestations: [PendingAttestation]

    let previousCrosslinks: [Crosslink]
    let currentCrosslinks: [Crosslink]

    let justificationBits: [Bool] // @todo

    let previousJustifiedCheckpoint: Checkpoint
    let currentJustifiedCheckpoint: Checkpoint
    let finalizedCheckpoint: Checkpoint

    mutating func increaseBalance(index: ValidatorIndex, delta: Gwei) {
        balances[Int(index)] += delta
    }

    mutating func decreaseBalance(index: ValidatorIndex, delta: Gwei) {
        if delta > balances[Int(index)] {
            return balances[Int(index)] = 0
        }

        balances[Int(index)] -= delta
    }

    mutating func initiateValidatorExit(_ index: ValidatorIndex) {
        var validator = validators[Int(index)]

        if validator.exitEpoch != FAR_FUTURE_EPOCH {
            return
        }

        var exitEpochs = validators.compactMap { v -> Epoch? in
            if v.exitEpoch != FAR_FUTURE_EPOCH {
                return v.exitEpoch
            }

            return nil
        }

//        exitEpochs.append(compute_activation_exit_epoch)
        var exitQueueEpoch = exitEpochs.max()!
        let exitQueueChurn = validators.filter { v in
            return v.exitEpoch == exitQueueEpoch
        }.count

        if exitQueueChurn >= getValidatorChurnLimit() {
            exitQueueEpoch += 1
        }

        validator.exitEpoch = exitQueueEpoch
        validator.withdrawableEpoch = Epoch(validator.exitEpoch + MIN_VALIDATOR_WITHDRAWABILITY_DELAY)

        validators[Int(index)] =  validator
    }

    mutating func slashValidator(_ index: ValidatorIndex, whistleblowerIndex: ValidatorIndex?) {
        let epoch = BeaconChain.getCurrentEpoch(state: self)
        initiateValidatorExit(index)

        var validator = validators[Int(index)]
        validator.slashed = true
        validator.withdrawableEpoch = max(validator.withdrawableEpoch, epoch + EPOCHS_PER_SLASHINGS_VECTOR)
        slashings[Int(epoch % EPOCHS_PER_SLASHINGS_VECTOR)] += validator.effectiveBalance

        decreaseBalance(index: index, delta: validator.effectiveBalance / MIN_SLASHING_PENALTY_QUOTIENT)

        let proposerIndex = BeaconChain.getBeaconProposerIndex(state: self, slot: slot)
        var whistleblower = proposerIndex
        if whistleblowerIndex != nil {
            whistleblower = whistleblowerIndex!
        }

        let whistleblowerReward = validator.effectiveBalance / WHISTLEBLOWER_REWARD_QUOTIENT
        let proposerReward = whistleblowerReward / PROPOSER_REWARD_QUOTIENT
        increaseBalance(index: proposerIndex, delta: proposerReward)
        increaseBalance(index: whistleblower, delta: whistleblowerReward - proposerReward)

        validators[Int(index)] = validator
    }

    func getValidatorChurnLimit() -> Int {
        return 0
    }

}
