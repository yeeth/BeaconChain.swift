import Foundation

class StateTransition {

    static func processSlot(state: inout BeaconState, previousBlockRoot: Data) {
        state.slot += 1
        state.validatorRegistry[BeaconChain.getBeaconProposerIndex(state: state, slot: state.slot)].randaoLayers += 1
        state.latestRandaoMixes[state.slot % LATEST_RANDAO_MIXES_LENGTH] = state.latestRandaoMixes[(state.slot - 1) % LATEST_RANDAO_MIXES_LENGTH]

        state.latestBlockRoots[(state.slot - 1) % LATEST_BLOCK_ROOTS_LENGTH] = previousBlockRoot
        if state.slot % LATEST_BLOCK_ROOTS_LENGTH == 0 {
            state.batchedBlockRoots.append(BeaconChain.merkleRoot(values: state.latestBlockRoots))
        }
    }
}

extension StateTransition {

    static func processBlock(state: inout BeaconState, block: Block) {
        assert(state.slot == block.slot) // @todo not sure if assert or other error handling

        proposerSignature(state: state, block: block)
        randao(state: &state, block: block)
        eth1Data(state: &state, block: block)
        proposerSlashings(state: &state, block: block)
        casperSlashings(state: &state, block: block)
        attestations(state: &state, block: block)
        deposits(state: &state, block: block)
        exits(state: &state, block: block)
    }

    private static func randao(state: inout BeaconState, block: Block) {
        let proposerIndex = BeaconChain.getBeaconProposerIndex(state: state, slot: state.slot)
        let proposer = state.validatorRegistry[proposerIndex]
        assert(repeatHash(data: block.randaoReveal, n: proposer.randaoLayers) == proposer.randaoCommitment)

        state.latestRandaoMixes[state.slot % LATEST_RANDAO_MIXES_LENGTH] = BeaconChain.hash(
            data: state.latestRandaoMixes[state.slot % LATEST_RANDAO_MIXES_LENGTH] ^ block.randaoReveal
        )

        state.validatorRegistry[proposerIndex].randaoCommitment = block.randaoReveal
        state.validatorRegistry[proposerIndex].randaoLayers = 0
    }

    private static func repeatHash(data: Data, n: Int) -> Data {
        if n == 0 {
            return data
        }

        return repeatHash(data: BeaconChain.hash(data: data), n: n - 1)
    }

    private static func proposerSignature(state: BeaconState, block: Block) {
        var signatureBlock = block
        signatureBlock.signature = EMPTY_SIGNATURE

        let proposalRoot = BeaconChain.hashTreeRoot(data: ProposalSignedData(
                slot: state.slot,
                shard: BEACON_CHAIN_SHARD_NUMBER,
                blockRoot: BeaconChain.hashTreeRoot(data: signatureBlock)
            )
        )

        assert(
            BLS.verify(
                pubkey: state.validatorRegistry[BeaconChain.getBeaconProposerIndex(state: state, slot: state.slot)].pubkey,
                message: proposalRoot,
                signature: block.signature,
                domain: BeaconChain.getDomain(data: state.fork, slot: state.slot, domainType: DOMAIN_PROPOSAL)
            )
        )
    }

    private static func eth1Data(state: inout BeaconState, block: Block) {
        for (i, eth1VoteData) in state.eth1DataVotes.enumerated() {
            if eth1VoteData.eth1Data == block.eth1Data {
                state.eth1DataVotes[i].voteCount += 1
            } else {
                state.eth1DataVotes.append(Eth1DataVote(eth1Data: block.eth1Data, voteCount: 1))
            }
        }
    }

    private static func proposerSlashings(state: inout BeaconState, block: Block) {
        for slashing in block.body.proposerSlashings {
            assert(slashing.proposalData1.slot == slashing.proposalData2.slot) // @todo not sure if asserts
            assert(slashing.proposalData1.shard == slashing.proposalData2.shard) // @todo not sure if asserts
            assert(slashing.proposalData1.blockRoot != slashing.proposalData2.blockRoot) // @todo not sure if asserts

            let proposer = state.validatorRegistry[slashing.proposerIndex]
            assert(proposer.penalizedSlot > state.slot) // @todo not sure if asserts

            assert(
                BLS.verify(
                    pubkey: proposer.pubkey,
                    message: BeaconChain.hashTreeRoot(data: slashing.proposalData1),
                    signature: slashing.proposalSignature1,
                    domain: BeaconChain.getDomain(data: state.fork, slot: slashing.proposalData1.slot, domainType: DOMAIN_PROPOSAL)
                )
            )
            assert(
                BLS.verify(
                    pubkey: proposer.pubkey,
                    message: BeaconChain.hashTreeRoot(data: slashing.proposalData2),
                    signature: slashing.proposalSignature2,
                    domain: BeaconChain.getDomain(data: state.fork, slot: slashing.proposalData2.slot, domainType: DOMAIN_PROPOSAL)
                )
            )

            BeaconChain.penalizeValidator(state: &state, index: slashing.proposerIndex)
        }
    }

    private static func casperSlashings(state: inout BeaconState, block: Block) {
        assert(block.body.casperSlashings.count <= MAX_CASPER_SLASHINGS)

        for slashing in block.body.casperSlashings {
            let slashableVoteData1 = slashing.slashableVoteData1
            let slashableVoteData2 = slashing.slashableVoteData2

            let slashableVoteData2Indices = indices(slashableVoteData: slashableVoteData2)
            let intersection = indices(slashableVoteData: slashableVoteData1).compactMap({
                (x) -> Int? in

                if slashableVoteData2Indices.firstIndex(of: x) != nil {
                    return x
                }

                return nil
            })

            assert(intersection.count >= 1)
            assert(slashableVoteData1.data != slashableVoteData2.data)

            assert(
                BeaconChain.isDoubleVote(first: slashableVoteData1.data, second: slashableVoteData2.data)
                || BeaconChain.isSurroundVote(first: slashableVoteData1.data, second: slashableVoteData2.data)
            )

            assert(BeaconChain.verifySlashableVoteData(state: state, data: slashableVoteData1))
            assert(BeaconChain.verifySlashableVoteData(state: state, data: slashableVoteData2))

            for i in intersection {
                if (state.validatorRegistry[i].penalizedSlot > state.slot) {
                    BeaconChain.penalizeValidator(state: &state, index: i)
                }
            }
        }
    }

    private static func indices(slashableVoteData data: SlashableVoteData) -> [Int] {
        return data.custodyBit0indices + data.custodyBit1indices
    }

    private static func deposits(state: inout BeaconState, block: Block) {
        assert(block.body.deposits.count <= MAX_DEPOSIT_AMOUNT)
        let serializedDepositData = Data(count: 64) // @todo when we have SSZ

        for deposit in block.body.deposits {
            assert(verifyMerkleBranch(
                    leaf: BeaconChain.hash(data: serializedDepositData),
                    branch: deposit.branch,
                    depth: DEPOSIT_CONTRACT_TREE_DEPTH,
                    index: deposit.index,
                    root: state.latestEth1Data.depositRoot
                )
            )

            BeaconChain.processDeposit(state: &state, deposit: deposit)
        }
    }

    private static func exits(state: inout BeaconState, block: Block) {
        assert(block.body.exits.count <= MAX_EXITS)

        for exit in block.body.exits {
            let validator = state.validatorRegistry[exit.validatorIndex]
            assert(validator.exitSlot > state.slot + ENTRY_EXIT_DELAY)
            assert(state.slot >= exit.slot)

            let exitMessage = BeaconChain.hashTreeRoot(data: Exit(
                    slot: exit.slot,
                    validatorIndex: exit.validatorIndex,
                    signature: EMPTY_SIGNATURE
                )
            )

            assert(
                BLS.verify(
                    pubkey: validator.pubkey,
                    message: exitMessage,
                    signature: exit.signature,
                    domain: BeaconChain.getDomain(data: state.fork, slot: state.slot, domainType: DOMAIN_EXIT)
                )
            )

            BeaconChain.initiateValidatorExit(state: &state, index: exit.validatorIndex)
        }
    }

    private static func attestations(state: inout BeaconState, block: Block) {
        assert(block.body.attestations.count <= MAX_ATTESTATIONS)

        for (_, attestation) in block.body.attestations.enumerated() {
            assert(attestation.data.slot + MIN_ATTESTATION_INCLUSION_DELAY <= state.slot)
            assert(attestation.data.slot + EPOCH_LENGTH >= state.slot)

            if attestation.data.slot >= state.slot - (state.slot % EPOCH_LENGTH) {
                assert(attestation.data.justifiedSlot == state.justifiedSlot)
            } else {
                assert(attestation.data.justifiedSlot == state.previousJustifiedSlot)
            }

            // wow this is ugly
            assert(
                attestation.data.justifiedBlockRoot == BeaconChain.getBlockRoot(
                    state: state,
                    slot: attestation.data.justifiedSlot
                )
            )

            assert(
                attestation.data.latestCrosslinkRoot == state.latestCrosslinks[attestation.data.shard].shardBlockRoot
                    || attestation.data.shardBlockRoot == state.latestCrosslinks[attestation.data.shard].shardBlockRoot
            )

            // @todo aggregate_signature verification

            assert(attestation.data.shardBlockRoot == ZERO_HASH)

            state.latestAttestations.append(
                PendingAttestation(
                    data: attestation.data,
                    aggregationBitfield: attestation.aggregationBitfield,
                    custodyBitfield: attestation.custodyBitfield,
                    slotIncluded: state.slot
                )
            )
        }
    }

    private static func verifyMerkleBranch(leaf: Data, branch: [Data], depth: Int, index: Int, root: Data) -> Bool {
        var value = leaf
        for i in 0...depth {
            if index / (2^i) % 2 == 1 {
                value = BeaconChain.hash(data: branch[i] + value)
            } else {
                value = BeaconChain.hash(data: value + branch[i])
            }
        }

        return value == root
    }
}

extension StateTransition {

    func processEpoch(state: inout BeaconState) {
        assert(state.slot % EPOCH_LENGTH == 1)
        let activeValidators = BeaconChain.getActiveValidatorIndices(validators: state.validatorRegistry, slot: state.slot)
        let totalBalance = activeValidators.map({
            (i: Int) -> Int in
            return BeaconChain.getEffectiveBalance(state: state, index: i)
        }).reduce(0, +)

        let currentEpochAttestations = state.latestAttestations.filter({
            state.slot - EPOCH_LENGTH <= $0.data.slot && $0.data.slot < state.slot
        })

        let currentEpochBoundryAttestations = currentEpochAttestations.filter({
            $0.data.epochBoundryRoot == BeaconChain.getBlockRoot(state: state, slot: state.slot - EPOCH_LENGTH)
                && $0.data.justifiedSlot == state.justifiedSlot
        })

        var currentEpochBoundaryAttesterIndices = Set<Int>()
        for attestation in currentEpochAttestations {
            currentEpochBoundaryAttesterIndices = currentEpochBoundaryAttesterIndices.union(
                BeaconChain.getAttestationParticipants(
                    state: state,
                    data: attestation.data,
                    aggregationBitfield: attestation.aggregationBitfield
                )
            )
        }

        let currentEpochBoundaryAttestingBalance = currentEpochBoundaryAttesterIndices.map({
            (i: Int) -> Int in
            return BeaconChain.getEffectiveBalance(state: state, index: i)
        }).reduce(0, +)

        let previousEpochAttestations = state.latestAttestations.filter({
            state.slot - (2 * EPOCH_LENGTH) <= $0.data.slot && $0.data.slot < state.slot - EPOCH_LENGTH
        })

        var previousEpochAttesterIndices = Set<Int>()
        for attestation in previousEpochAttestations {
            previousEpochAttesterIndices = previousEpochAttesterIndices.union(
                BeaconChain.getAttestationParticipants(
                    state: state,
                    data: attestation.data,
                    aggregationBitfield: attestation.aggregationBitfield
                )
            )
        }

        let previousEpochJustifiedAttestations = (currentEpochBoundryAttestations + previousEpochAttestations).filter({
            $0.data.justifiedSlot == state.justifiedSlot
        })

        var previousEpochJustifiedAttesterIndices = Set<Int>()
        for attestation in previousEpochAttestations {
            previousEpochJustifiedAttesterIndices = previousEpochJustifiedAttesterIndices.union(
                BeaconChain.getAttestationParticipants(
                    state: state,
                    data: attestation.data,
                    aggregationBitfield: attestation.aggregationBitfield
                )
            )
        }

        let previousEpochJustifiedAttestingBalance = previousEpochJustifiedAttesterIndices.map({
            (i: Int) -> Int in
            return BeaconChain.getEffectiveBalance(state: state, index: i)
        }).reduce(0, +)

        let previousEpochBoundaryAttestations = previousEpochJustifiedAttestations.filter({
            $0.data.epochBoundryRoot == BeaconChain.getBlockRoot(state: state, slot: state.slot - 2 * EPOCH_LENGTH)
        })

        var previousEpochBoundaryAttesterIndices = Set<Int>()
        for attestation in previousEpochBoundaryAttestations {
            previousEpochBoundaryAttesterIndices = previousEpochBoundaryAttesterIndices.union(
                BeaconChain.getAttestationParticipants(
                    state: state,
                    data: attestation.data,
                    aggregationBitfield: attestation.aggregationBitfield
                )
            )
        }

        let previousEpochBoundaryAttestingBalance = previousEpochJustifiedAttesterIndices.map({
            (i: Int) -> Int in
            return BeaconChain.getEffectiveBalance(state: state, index: i)
        }).reduce(0, +)

        let previousEpochHeadAttestations = previousEpochAttestations.filter({
            $0.data.beaconBlockRoot == BeaconChain.getBlockRoot(state: state, slot: state.slot)
        })

        var previousEpochHeadAttesterIndices = Set<Int>()
        for attestation in previousEpochHeadAttestations {
            previousEpochHeadAttesterIndices = previousEpochHeadAttesterIndices.union(
                BeaconChain.getAttestationParticipants(
                    state: state,
                    data: attestation.data,
                    aggregationBitfield: attestation.aggregationBitfield
                )
            )
        }

        let previousEpochHeadAttestingBalance = previousEpochHeadAttesterIndices.map({
            (i: Int) -> Int in
            return BeaconChain.getEffectiveBalance(state: state, index: i)
        }).reduce(0, +)

        // @TODO
        // For every slot in range(state.slot - 2 * EPOCH_LENGTH, state.slot), let crosslink_committee_at_slot = get_crosslink_committees_at_slot(slot). For every (crosslink_committee, shard) in crosslink_committee_at_slot, compute:

        eth1Data(state: &state)
        justification(
            state: &state,
            totalBalance: totalBalance,
            previousEpochBoundaryAttestingBalance: previousEpochBoundaryAttestingBalance,
            currentEpochBoundaryAttestingBalance: currentEpochBoundaryAttestingBalance
        )

        // @todo Crosslinks

        rewardsAndPenalties(
            state: &state,
            totalBalance: totalBalance,
            previousEpochJustifiedAttesterIndices: Array(previousEpochJustifiedAttesterIndices),
            previousEpochJustifiedAttestingBalance: previousEpochJustifiedAttestingBalance,
            previousEpochBoundaryAttesterIndices: Array(previousEpochBoundaryAttesterIndices),
            previousEpochBoundaryAttestingBalance: previousEpochBoundaryAttestingBalance,
            previousEpochHeadAttesterIndices: Array(previousEpochHeadAttesterIndices),
            previousEpochHeadAttestingBalance: previousEpochHeadAttestingBalance,
            previousEpochAttesterIndices: Array(previousEpochAttesterIndices)
        )

        for i in BeaconChain.getActiveValidatorIndices(validators: state.validatorRegistry, slot: state.slot) {
            if state.validatorBalances[i] < EJECTION_BALANCE {
                BeaconChain.exitValidator(state: &state, index: i)
            }
        }

        validatorRegistry(state: &state)
        processPenaltiesAndExits(state: &state)

        let e = state.slot / EPOCH_LENGTH
        state.latestPenalizedBalances[(e + 1) % LATEST_PENALIZED_EXIT_LENGTH] = state.latestPenalizedBalances[e % LATEST_PENALIZED_EXIT_LENGTH]
        state.latestAttestations.removeAll { $0.data.slot < state.slot - EPOCH_LENGTH }
    }

    private func eth1Data(state: inout BeaconState) {
        if state.slot % ETH1_DATA_VOTING_PERIOD != 0 {
            return
        }

        for eth1DataVote in state.eth1DataVotes {
            if eth1DataVote.voteCount * 2 > ETH1_DATA_VOTING_PERIOD {
                state.latestEth1Data = eth1DataVote.eth1Data
            }
        }

        state.eth1DataVotes = [Eth1DataVote]()
    }

    private func justification(
        state: inout BeaconState,
        totalBalance: Int,
        previousEpochBoundaryAttestingBalance: Int,
        currentEpochBoundaryAttestingBalance: Int
    )
    {
        state.previousJustifiedSlot = state.justifiedSlot
        state.justificationBitfield = (state.justificationBitfield * 2) % 2^64

        if 3 * previousEpochBoundaryAttestingBalance >= 2 * totalBalance {
            state.justificationBitfield |= 2
            state.justifiedSlot = state.slot - 2 * EPOCH_LENGTH
        }

        if 3 * currentEpochBoundaryAttestingBalance >= 2 * totalBalance {
            state.justificationBitfield |= 1
            state.justifiedSlot = state.slot - 1 * EPOCH_LENGTH
        }

        if (state.previousJustifiedSlot == state.slot - 2 * EPOCH_LENGTH && state.justificationBitfield % 4 == 3)
            || (state.previousJustifiedSlot == state.slot - 3 * EPOCH_LENGTH && state.justificationBitfield % 8 == 7)
            || (state.previousJustifiedSlot == state.slot - 4 * EPOCH_LENGTH && [15, 14].contains(state.justificationBitfield % 16))
        {
            state.finalizedSlot = state.previousJustifiedSlot
        }
    }

    private func crosslink(
        state: inout BeaconState,
        totalBalance: [Data:Int],
        totalAttesstingBalance: [Data:Int],
        winningRoot: [Data:Data]
    )
    {

        // @todo define totalBalance, totalAttestingBalance, winningRoot as functions
        // Let winning_root(crosslink_committee) be equal to the value of shard_block_root such that
        //   sum([get_effective_balance(state, i) for i in attesting_validator_indices(crosslink_committee,
        //   shard_block_root)]) is maximized (ties broken by favoring lower shard_block_root values).
        // Let attesting_validators(crosslink_committee) be equal to attesting_validator_indices(crosslink_committee,
        //    winning_root(crosslink_committee)) for convenience.
        // Let total_attesting_balance(crosslink_committee) = sum([get_effective_balance(state, i) for i in
        //    attesting_validators(crosslink_committee)]).
        // Let total_balance(crosslink_committee) = sum([get_effective_balance(state, i) for i in crosslink_committee]).

        for slot in (state.slot - 2 * EPOCH_LENGTH)...state.slot {
            let crosslinkCommitteeAtSlot = BeaconChain.getCrosslinkCommitteesAtSlot(state: state, slot: slot)
            for (committee, shard) in crosslinkCommitteeAtSlot {
                let crosslinkCommittee = committee.withUnsafeBufferPointer { Data(buffer: $0) }
                if 3 * totalAttesstingBalance[crosslinkCommittee]! >= 2 * totalBalance[crosslinkCommittee]! {
                    state.latestCrosslinks[shard] = Crosslink(
                        slot: state.slot,
                        shardBlockRoot: winningRoot[crosslinkCommittee]!
                    )
                }
            }
        }
    }

    private func rewardsAndPenalties(
        state: inout BeaconState,
        totalBalance: Int,
        previousEpochJustifiedAttesterIndices: [Int],
        previousEpochJustifiedAttestingBalance: Int,
        previousEpochBoundaryAttesterIndices: [Int],
        previousEpochBoundaryAttestingBalance: Int,
        previousEpochHeadAttesterIndices: [Int],
        previousEpochHeadAttestingBalance: Int,
        previousEpochAttesterIndices: [Int]
    )
    {
        let epochsSinceFinality = (state.slot - state.finalizedSlot) / EPOCH_LENGTH

        let activeValidators = Set(
            BeaconChain.getActiveValidatorIndices(validators: state.validatorRegistry, slot: state.slot)
        )

        if epochsSinceFinality <= 4 {
            for index in previousEpochJustifiedAttesterIndices {
                state.validatorBalances[index] += baseReward(state: state, index: index, totalBalance: totalBalance) * previousEpochJustifiedAttestingBalance / totalBalance
            }

            activeValidators.subtracting(Set(previousEpochJustifiedAttesterIndices)).forEach({
                (index) in
                state.validatorBalances[index] -= baseReward(state: state, index: index, totalBalance: totalBalance)
            })

            for index in previousEpochBoundaryAttesterIndices {
                state.validatorBalances[index] += baseReward(state: state, index: index, totalBalance: totalBalance) * previousEpochBoundaryAttestingBalance / totalBalance
            }

            activeValidators.subtracting(Set(previousEpochBoundaryAttesterIndices)).forEach({
                (index) in
                state.validatorBalances[index] -= baseReward(state: state, index: index, totalBalance: totalBalance)
            })

            for index in previousEpochHeadAttesterIndices {
                state.validatorBalances[index] += baseReward(state: state, index: index, totalBalance: totalBalance) * previousEpochHeadAttestingBalance / totalBalance
            }

            activeValidators.subtracting(Set(previousEpochHeadAttesterIndices)).forEach({
                (index) in
                state.validatorBalances[index] -= baseReward(state: state, index: index, totalBalance: totalBalance)
            })

            for index in previousEpochAttesterIndices {
                state.validatorBalances[index] += baseReward(state: state, index: index, totalBalance: totalBalance) + MIN_ATTESTATION_INCLUSION_DELAY / inclusionDistance(state: state, index: index)
            }
        } else {
            activeValidators.subtracting(Set(previousEpochJustifiedAttesterIndices)).forEach({
                (index) in
                state.validatorBalances[index] -= inactivityPenalty(state: state, index: index, epochsSinceFinality: epochsSinceFinality, totalBalance: totalBalance)
            })

            activeValidators.subtracting(Set(previousEpochBoundaryAttesterIndices)).forEach({
                (index) in
                state.validatorBalances[index] -= inactivityPenalty(state: state, index: index, epochsSinceFinality: epochsSinceFinality, totalBalance: totalBalance)
            })

            activeValidators.subtracting(Set(previousEpochHeadAttesterIndices)).forEach({
                (index) in
                state.validatorBalances[index] -= baseReward(state: state, index: index, totalBalance: totalBalance)
            })

            activeValidators.forEach({
                index in
                if state.validatorRegistry[index].penalizedSlot <= state.slot {
                    state.validatorBalances[index] -= 2 * inactivityPenalty(state: state, index: index, epochsSinceFinality: epochsSinceFinality, totalBalance: totalBalance) + baseReward(state: state, index: index, totalBalance: totalBalance)
                }
            })

            for index in previousEpochAttesterIndices {
                let base = baseReward(state: state, index: index, totalBalance: totalBalance)
                state.validatorBalances[index] -= base - base * MIN_ATTESTATION_INCLUSION_DELAY / inclusionDistance(state: state, index: index)
            }
        }

        for index in previousEpochAttesterIndices {
            let proposer = BeaconChain.getBeaconProposerIndex(state: state, slot: inclusionSlot(state: state, index: index))
            state.validatorBalances[proposer] += baseReward(state: state, index: index, totalBalance: totalBalance)
        }

        for i in (state.slot - 2 * EPOCH_LENGTH)...(state.slot - EPOCH_LENGTH) {
            let crosslinkCommitteesAtSlot = BeaconChain.getCrosslinkCommitteesAtSlot(state: state, slot: state.slot)

            for (_, (committee, shard)) in crosslinkCommitteesAtSlot.enumerated() {
//                state.latestCrosslinks[shard] = Crosslink(
//                    slot: state.slot,
//                    shardBlockRoot: winni)
            }
        }
    }

    private func validatorRegistry(state: inout BeaconState) {
        // @todo if
        if true {
            BeaconChain.updateValidatorRegistry(state: &state)
            state.previousEpochCalculationSlot = state.currentEpochCalculationSlot
            state.previousEpochStartShard = state.currentEpochStartShard
            state.previousEpochRandaoMix = state.currentEpochRandaoMix
            state.currentEpochCalculationSlot = state.slot
            state.currentEpochStartShard = (state.currentEpochStartShard + BeaconChain.getCurrentEpochCommitteeCountPerSlot(state: state) % EPOCH_LENGTH) % SHARD_COUNT
            state.currentEpochRandaoMix = BeaconChain.getRandaoMix(
                state: state,
                slot: state.currentEpochCalculationSlot - SEED_LOOKAHEAD
            )
        } else {
            state.previousEpochCalculationSlot = state.currentEpochCalculationSlot
            state.previousEpochStartShard = state.currentEpochStartShard

            let epochsSinceLastRegistryChange = (state.slot - state.validatorRegistryUpdateSlot) / EPOCH_LENGTH
            if isPowerOfTwo(epochsSinceLastRegistryChange) {
                state.currentEpochCalculationSlot = state.slot
                state.currentEpochRandaoMix = state.latestRandaoMixes[(state.currentEpochCalculationSlot - SEED_LOOKAHEAD) % LATEST_RANDAO_MIXES_LENGTH]
            }
        }
    }

    private func inclusionDistance(state: BeaconState, index: Int) -> Int {
        return 0 // @todo
    }

    private func inclusionSlot(state: BeaconState, index: Int) -> Int {
        return 0 // @todo
    }

    private func baseReward(state: BeaconState, index: Int, totalBalance: Int) -> Int {
        let baseRewardQoutient = BeaconChain.integerSquareRoot(n: totalBalance) / BASE_REWARD_QUOTIENT
        return BeaconChain.getEffectiveBalance(state: state, index: index) / baseRewardQoutient / 5
    }

    private func inactivityPenalty(state: BeaconState, index: Int, epochsSinceFinality: Int, totalBalance: Int) -> Int {
        return baseReward(state: state, index: index, totalBalance: totalBalance) * epochsSinceFinality / INACTIVITY_PENALTY_QUOTIENT / 2
    }

    // @todo maybe make these extension functions on an int?
    private func isPowerOfTwo(_ n: Int) -> Bool {
        return ceil(log2(n)) == floor(log2(n))
    }

    private func log2(_ n: Int) -> Double {
        return log10(Double(n)) / log10(2.0)
    }

    private func processPenaltiesAndExits(state: inout BeaconState) {
        let activeValidators = BeaconChain.getActiveValidatorIndices(validators: state.validatorRegistry, slot: state.slot)
        let totalBalance = activeValidators.map({
            (i: Int) -> Int in
            return BeaconChain.getEffectiveBalance(state: state, index: i)
        }).reduce(0, +)

        for (i, validator) in state.validatorRegistry.enumerated() {
            if (state.slot / EPOCH_LENGTH) != (validator.penalizedSlot / EPOCH_LENGTH) + LATEST_PENALIZED_EXIT_LENGTH / 2 {
                continue
            }

            let e = (state.slot / EPOCH_LENGTH) % LATEST_PENALIZED_EXIT_LENGTH
            let totalAtStart = state.latestPenalizedBalances[(e + 1) % LATEST_PENALIZED_EXIT_LENGTH]
            let totalAtEnd = state.latestPenalizedBalances[e]
            let totalPenalties = totalAtEnd - totalAtStart
            let penalty = BeaconChain.getEffectiveBalance(state: state, index: i) * min(totalPenalties * 3, totalBalance) / totalBalance
            state.validatorBalances[i] -= penalty

            var eligibleIndices = (0...state.validatorRegistry.count).filter({
                let validator = state.validatorRegistry[$0]
                if validator.penalizedSlot <= state.slot {
                    let PENALIZED_WITHDRAWAL_TIME = LATEST_PENALIZED_EXIT_LENGTH * EPOCH_LENGTH // 2
                    return state.slot >= validator.penalizedSlot + PENALIZED_WITHDRAWAL_TIME
                } else {
                    return state.slot >= validator.exitSlot + MIN_VALIDATOR_WITHDRAWAL_TIME
                }
            })

            eligibleIndices.sort {
                state.validatorRegistry[$0].exitCount > state.validatorRegistry[$1].exitCount
            }

            var withdrawan = 0
            for i in eligibleIndices {
                BeaconChain.prepareValidatorForWithdrawal(state: &state, index: i)
                withdrawan += 1
                if withdrawan >= MAX_WITHDRAWALS_PER_EPOCH {
                    break
                }
            }
        }
    }

    func attestingValidatorIndices(committee: [Int], shardBlockRoot: Data) -> [Int] {
        var indices = [Int]()

//        for

        return indices // @todo
    }

    func winningRoot(committee: [Int]) -> Data {
        return Data(count: 0) // @todo
    }
}
