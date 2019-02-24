import Foundation

// @todo refactor so this isn't all in one class

class StateTransition {

    static func processSlot(state: inout BeaconState, previousBlockRoot: Data) {
        state.slot += 1
        state.latestBlockRoots[Int((state.slot - 1) % LATEST_BLOCK_ROOTS_LENGTH)] = previousBlockRoot

        if state.slot % LATEST_BLOCK_ROOTS_LENGTH == 0 {
            state.batchedBlockRoots.append(BeaconChain.merkleRoot(values: state.latestBlockRoots))
        }
    }
}

extension StateTransition {

    static func processBlock(state: inout BeaconState, block: BeaconBlock) {
        assert(state.slot == block.slot)

        proposerSignature(state: &state, block: block)
        randao(state: &state, block: block)
        eth1data(state: &state, block: block)
        proposerSlashings(state: &state, block: block)
        attesterSlashings(state: &state, block: block)
        attestations(state: &state, block: block)
        deposits(state: &state, block: block)
        exits(state: &state, block: block)
    }

    static func proposerSignature(state: inout BeaconState, block: BeaconBlock) {
        var signatureBlock = block
        signatureBlock.signature = EMPTY_SIGNATURE

        let proposalRoot = BeaconChain.hashTreeRoot(ProposalSignedData(
                slot: state.slot,
                shard: BEACON_CHAIN_SHARD_NUMBER,
                blockRoot: BeaconChain.hashTreeRoot(signatureBlock)
            )
        )

        assert(
            BLS.verify(
                pubkey: state.validatorRegistry[Int(BeaconChain.getBeaconProposerIndex(state: state, slot: state.slot))].pubkey,
                message: proposalRoot,
                signature: block.signature,
                domain: BeaconChain.getDomain(
                    fork: state.fork,
                    epoch: BeaconChain.getCurrentEpoch(state: state),
                    domainType: Domain.PROPOSAL
                )
            )
        )
    }

    static func randao(state: inout BeaconState, block: BeaconBlock) {
        let proposer = state.validatorRegistry[Int(BeaconChain.getBeaconProposerIndex(state: state, slot: state.slot))]

        var epoch = BeaconChain.getCurrentEpoch(state: state)
        assert(
            BLS.verify(
                pubkey: proposer.pubkey,
                message: Data(bytes: &epoch, count: 32),
                signature: block.randaoReveal,
                domain: BeaconChain.getDomain(fork: state.fork, epoch: BeaconChain.getCurrentEpoch(state: state), domainType: Domain.RANDAO)
            )
        )

        state.latestRandaoMixes[Int(BeaconChain.getCurrentEpoch(state: state) % LATEST_RANDAO_MIXES_LENGTH)] = BeaconChain.getRandaoMix(state: state, epoch: BeaconChain.getCurrentEpoch(state: state)) ^ BeaconChain.hash(block.randaoReveal)
    }

    static func eth1data(state: inout BeaconState, block: BeaconBlock) {
        for (i, vote) in state.eth1DataVotes.enumerated() {
            if vote.eth1Data == block.eth1Data {
                state.eth1DataVotes[i].voteCount += 1
                continue
            }

            state.eth1DataVotes.append(Eth1DataVote(eth1Data: block.eth1Data, voteCount: 1))
        }
    }

    static func proposerSlashings(state: inout BeaconState, block: BeaconBlock) {
        assert(block.body.proposerSlashings.count <= MAX_PROPOSER_SLASHINGS)

        for proposerSlashing in block.body.proposerSlashings {
            let proposer = state.validatorRegistry[Int(proposerSlashing.proposerIndex)]
            let epoch = BeaconChain.getCurrentEpoch(state: state)
            // @todo none of these should be asserts
            assert(proposerSlashing.proposalData1.slot == proposerSlashing.proposalData2.slot)
            assert(proposerSlashing.proposalData1.shard == proposerSlashing.proposalData2.shard)
            assert(proposerSlashing.proposalData1.blockRoot != proposerSlashing.proposalData2.blockRoot)
            assert(proposer.penalizedEpoch > epoch)

            assert(
                BLS.verify(
                    pubkey: proposer.pubkey,
                    message: BeaconChain.hashTreeRoot(proposerSlashing.proposalData1),
                    signature: proposerSlashing.proposalSignature1,
                    domain: BeaconChain.getDomain(fork: state.fork, epoch: epoch, domainType: Domain.PROPOSAL)
                )
            )

            assert(
                BLS.verify(
                    pubkey: proposer.pubkey,
                    message: BeaconChain.hashTreeRoot(proposerSlashing.proposalData2),
                    signature: proposerSlashing.proposalSignature2,
                    domain: BeaconChain.getDomain(fork: state.fork, epoch: epoch, domainType: Domain.PROPOSAL)
                )
            )

            BeaconChain.penalizeValidator(state: &state, index: proposerSlashing.proposerIndex)
        }
    }

    static func attesterSlashings(state: inout BeaconState, block: BeaconBlock) {
        assert(block.body.attesterSlashings.count <= MAX_ATTESTER_SLASHINGS)

        for attesterSlashing in block.body.attesterSlashings {
            let slashableAttestation1 = attesterSlashing.slashableAttestation1
            let slashableAttestation2 = attesterSlashing.slashableAttestation2

            assert(slashableAttestation1.data != slashableAttestation2.data)
            assert(
                BeaconChain.isDoubleVote(slashableAttestation1.data, slashableAttestation2.data)
                    || BeaconChain.isSurroundVote(slashableAttestation1.data, slashableAttestation2.data)
            )

            assert(BeaconChain.verifySlashableAttestation(state: state, slashableAttestation: slashableAttestation1))
            assert(BeaconChain.verifySlashableAttestation(state: state, slashableAttestation: slashableAttestation2))

            let slashableIndices = slashableAttestation1.validatorIndices.filter {
                slashableAttestation2.validatorIndices.contains($0)
                    && state.validatorRegistry[Int($0)].penalizedEpoch > BeaconChain.getCurrentEpoch(state: state)
            }

            assert(slashableIndices.count >= 1)

            for i in slashableIndices {
                BeaconChain.penalizeValidator(state: &state, index: i)
            }
        }
    }

    static func attestations(state: inout BeaconState, block: BeaconBlock) {
        assert(block.body.attestations.count <= MAX_ATTESTATIONS)

        for attestation in block.body.attestations {
            assert(attestation.data.slot <= state.slot - MIN_ATTESTATION_INCLUSION_DELAY)
            assert(state.slot - MIN_ATTESTATION_INCLUSION_DELAY < attestation.data.slot + SLOTS_PER_EPOCH)

            let e = attestation.data.justifiedEpoch >= BeaconChain.getCurrentEpoch(state: state) ? state.justifiedEpoch : state.previousJustifiedEpoch
            assert(attestation.data.justifiedEpoch == e)
            assert(attestation.data.justifiedBlockRoot == BeaconChain.getBlockRoot(state: state, slot: attestation.data.justifiedEpoch.startSlot()))

            assert(
                state.latestCrosslinks[Int(attestation.data.shard)] == attestation.data.latestCrosslink ||
                state.latestCrosslinks[Int(attestation.data.shard)] == Crosslink(
                    epoch: attestation.data.slot.toEpoch(),
                    shardBlockRoot: attestation.data.shardBlockRoot
                )
            )

            assert(attestation.custodyBitfield == Data(repeating: 0, count: 32))
            assert(attestation.aggregationBitfield != Data(repeating: 0, count: 32))

            let crosslinkCommittee = BeaconChain.getCrosslinkCommitteesAtSlot(state: state, slot: attestation.data.slot).filter {
                $0.1 == attestation.data.shard
            }.first?.0

            for i in 0..<crosslinkCommittee!.count {
                if BeaconChain.getBitfieldBit(bitfield: attestation.aggregationBitfield, i: i) == 0b0 {
                    assert(BeaconChain.getBitfieldBit(bitfield: attestation.custodyBitfield, i: i) == 0b1)
                }
            }

            let participants = BeaconChain.getAttestationParticipants(
                state: state,
                attestationData: attestation.data,
                bitfield: attestation.aggregationBitfield
            )

            let custodyBit1Participants = BeaconChain.getAttestationParticipants(
                state: state,
                attestationData: attestation.data,
                bitfield: attestation.custodyBitfield
            )

            let custodyBit0Participants = participants.filter {
                !custodyBit1Participants.contains($0)
            }

            assert(
                BLS.verify(
                    pubkeys: [
                        BLS.aggregate(pubkeys: custodyBit0Participants.map {
                            return state.validatorRegistry[Int($0)].pubkey
                        }),
                        BLS.aggregate(pubkeys: custodyBit1Participants.map {
                            return state.validatorRegistry[Int($0)].pubkey
                        })
                    ],
                    messages: [
                        BeaconChain.hashTreeRoot(AttestationDataAndCustodyBit(data: attestation.data, custodyBit: false)),
                        BeaconChain.hashTreeRoot(AttestationDataAndCustodyBit(data: attestation.data, custodyBit: true))
                    ],
                    signature: attestation.aggregateSignature,
                    domain: BeaconChain.getDomain(
                        fork: state.fork,
                        epoch: attestation.data.slot.toEpoch(),
                        domainType: Domain.ATTESTATION
                    )
                )
            )

            assert(attestation.data.shardBlockRoot == ZERO_HASH) // @todo remove in phase 1

            state.latestAttestations.append(
                PendingAttestation(
                    aggregationBitfield: attestation.aggregationBitfield, data: attestation.data,
                    custodyBitfield: attestation.custodyBitfield,
                    inclusionSlot: state.slot
                )
            )
        }
    }

    static func deposits(state: inout BeaconState, block: BeaconBlock) {
        assert(block.body.deposits.count <= MAX_DEPOSITS)

        for deposit in block.body.deposits {
            let serializedDepositData = Data(count: 64) // @todo when we have SSZ

            assert(
                verifyMerkleBranch(
                    leaf: BeaconChain.hash(serializedDepositData),
                    branch: deposit.branch,
                    depth: Int(DEPOSIT_CONTRACT_TREE_DEPTH),
                    index: Int(deposit.index),
                    root: state.latestEth1Data.depositRoot
                )
            )

            BeaconChain.processDeposit(
                state: &state,
                pubkey: deposit.depositData.depositInput.pubkey,
                amount: deposit.depositData.amount,
                proofOfPossession: deposit.depositData.depositInput.proofOfPossession,
                withdrawalCredentials: deposit.depositData.depositInput.withdrawalCredentials
            )
        }
    }

    static func exits(state: inout BeaconState, block: BeaconBlock) {
        assert(block.body.exits.count <= MAX_VOLUNTARY_EXITS)

        for exit in block.body.exits {
            let validator = state.validatorRegistry[Int(exit.validatorIndex)]

            let epoch = BeaconChain.getCurrentEpoch(state: state)
            assert(validator.exitEpoch > epoch.entryExitEpoch())
            assert(epoch >= exit.epoch)

            let exitMessage = BeaconChain.hashTreeRoot(
                Exit(epoch: exit.epoch, validatorIndex: exit.validatorIndex, signature: EMPTY_SIGNATURE)
            )

            assert(
                BLS.verify(
                    pubkey: validator.pubkey,
                    message: exitMessage,
                    signature: exit.signature,
                    domain: BeaconChain.getDomain(fork: state.fork, epoch: exit.epoch, domainType: Domain.EXIT)
                )
            )

            BeaconChain.initiateValidatorExit(state: &state, index: exit.validatorIndex)
        }
    }

    static func verifyMerkleBranch(leaf: Bytes32, branch: [Bytes32], depth: Int, index: Int, root: Bytes32) -> Bool {
        var value = leaf
        for i in 0..<depth {
            if index / (2 ** i) % 2 == 1 {
                value = BeaconChain.hash(branch[i] + value)
            } else {
                value = BeaconChain.hash(value + branch[i])
            }
        }

        return value == root
    }
}

extension StateTransition {

    static func processEpoch(state: inout BeaconState) {
        assert(state.slot + 1 % SLOTS_PER_EPOCH == 0) // @todo not sure if this should be here

        let currentEpoch = BeaconChain.getCurrentEpoch(state: state)
        let previousEpoch = BeaconChain.getPreviousEpoch(state: state)
        let nextEpoch = currentEpoch + 1

        let currentTotalBalance = state.validatorRegistry.activeIndices(epoch: currentEpoch).totalBalance(state: state)

        let currentEpochAttestations = state.latestAttestations.filter {
            currentEpoch == $0.data.slot.toEpoch()
        }

        let currentEpochBoundryAttestations = currentEpochAttestations.filter {
            $0.data.epochBoundaryRoot == BeaconChain.getBlockRoot(state: state, slot: currentEpoch.startSlot())
                && $0.data.justifiedEpoch == state.justifiedEpoch
        }

        let currentEpochBoundaryAttesterIndices = currentEpochBoundryAttestations.flatMap {
            return BeaconChain.getAttestationParticipants(state: state, attestationData: $0.data, bitfield: $0.aggregationBitfield)
        }

        let currentEpochBoundaryAttestingBalance = (currentEpochBoundaryAttesterIndices as [ValidatorIndex]).totalBalance(state: state)

        let previousTotalBalance = state.validatorRegistry.activeIndices(epoch: previousEpoch).totalBalance(state: state)

        let previousEpochAttestations = state.latestAttestations.filter {
            previousEpoch == $0.data.slot.toEpoch()
        }

        let previousEpochAttesterIndices = previousEpochAttestations.flatMap {
            return BeaconChain.getAttestationParticipants(state: state, attestationData: $0.data, bitfield: $0.aggregationBitfield)
        }

        let previousEpochJustifiedAttestations = (currentEpochAttestations + previousEpochAttestations).filter {
            $0.data.justifiedEpoch == state.previousJustifiedEpoch
        }

        let previousEpochJustifiedAttesterIndices = previousEpochJustifiedAttestations.flatMap {
            return BeaconChain.getAttestationParticipants(state: state, attestationData: $0.data, bitfield: $0.aggregationBitfield)
        }

        let previousEpochJustifiedAttestingBalance = (previousEpochJustifiedAttesterIndices as [ValidatorIndex]).totalBalance(state: state)

        let previousEpochBoundaryAttestations = previousEpochJustifiedAttestations.filter {
            $0.data.epochBoundaryRoot == BeaconChain.getBlockRoot(state: state, slot: previousEpoch.startSlot())
        }

        let previousEpochBoundaryAttesterIndices = previousEpochBoundaryAttestations.flatMap {
            return BeaconChain.getAttestationParticipants(state: state, attestationData: $0.data, bitfield: $0.aggregationBitfield)
        }

        let previousEpochBoundaryAttestingBalance = (previousEpochBoundaryAttesterIndices as [ValidatorIndex]).totalBalance(state: state)

        let previousEpochHeadAttestations = previousEpochAttestations.filter {
            $0.data.beaconBlockRoot == BeaconChain.getBlockRoot(state: state, slot: $0.data.slot)
        }

        let previousEpochHeadAttesterIndices = previousEpochHeadAttestations.flatMap {
            return BeaconChain.getAttestationParticipants(state: state, attestationData: $0.data, bitfield: $0.aggregationBitfield)
        }

        let previousEpochHeadAttestingBalance = (previousEpochHeadAttesterIndices as [ValidatorIndex]).totalBalance(state: state)

        eth1data(state: &state, nextEpoch: nextEpoch)

        justification(
            state: &state,
            previousEpoch: previousEpoch,
            currentEpoch: currentEpoch,
            previousTotalBalance: previousTotalBalance,
            previousEpochBoundaryAttestingBalance: previousEpochBoundaryAttestingBalance,
            currentTotalBalance: currentTotalBalance,
            currentEpochBoundaryAttestingBalance: currentEpochBoundaryAttestingBalance
        )

        crosslink(
            state: &state,
            previousEpoch: previousEpoch,
            currentEpoch: currentEpoch,
            nextEpoch: nextEpoch,
            currentEpochAttestations: currentEpochAttestations,
            previousEpochAttestations: previousEpochAttestations
        )

        rewardsAndPenalties(
            state: &state,
            previousEpoch: previousEpoch,
            currentEpoch: currentEpoch,
            nextEpoch: nextEpoch,
            previousTotalBalance: previousTotalBalance,
            totalBalance: currentTotalBalance,
            previousEpochJustifiedAttesterIndices: previousEpochJustifiedAttesterIndices,
            previousEpochJustifiedAttestingBalance: previousEpochJustifiedAttestingBalance,
            previousEpochBoundaryAttesterIndices: previousEpochBoundaryAttesterIndices,
            previousEpochBoundaryAttestingBalance: previousEpochBoundaryAttestingBalance,
            previousEpochHeadAttesterIndices: previousEpochHeadAttesterIndices,
            previousEpochHeadAttestingBalance: previousEpochHeadAttestingBalance,
            previousEpochAttesterIndices: previousEpochAttesterIndices,
            currentEpochAttestations: currentEpochAttestations,
            previousEpochAttestations: previousEpochAttestations
        )

        processEjections(state: &state)

        shufflingSeedData(state: &state, nextEpoch: nextEpoch)

        let shards = (0..<BeaconChain.getCurrentEpochCommitteeCount(state: state)).filter {
            state.latestCrosslinks[Int((state.currentCalculationEpoch + UInt64($0)) % SHARD_COUNT)].epoch <= state.validatorRegistryUpdateEpoch
        }

        if state.finalizedEpoch > state.validatorRegistryUpdateEpoch && shards.count == 0 {
            updateValidatorRegistry(state: &state)
        } else {
            let epochsSinceLastRegistryUpdate = currentEpoch - state.validatorRegistryUpdateEpoch
            if epochsSinceLastRegistryUpdate > 1 && Int(epochsSinceLastRegistryUpdate).isPowerOfTwo() {
                state.currentCalculationEpoch = nextEpoch
                state.currentEpochSeed = BeaconChain.generateSeed(state: state, epoch: state.currentCalculationEpoch)
            }
        }

        processPenaltiesAndExit(state: &state)

        state.latestIndexRoots[Int((nextEpoch % ACTIVATION_EXIT_DELAY) % LATEST_ACTIVE_INDEX_ROOTS_LENGTH)] = BeaconChain.hashTreeRoot(
            state.validatorRegistry.activeIndices(epoch: nextEpoch + ACTIVATION_EXIT_DELAY)
        )

        state.latestPenalizedBalances[Int(nextEpoch % LATEST_SLASHED_EXIT_LENGTH)] = state.latestPenalizedBalances[Int(currentEpoch % LATEST_SLASHED_EXIT_LENGTH)]
        state.latestRandaoMixes[Int(nextEpoch % LATEST_RANDAO_MIXES_LENGTH)] = BeaconChain.getRandaoMix(
            state: state,
            epoch: currentEpoch
        )

        // @todo check this
        // Remove any attestation in state.latest_attestations such that slot_to_epoch(attestation.data.slot) < current_epoch.
        state.latestAttestations.removeAll {
            $0.data.slot.toEpoch() >= currentEpoch
        }
    }

    private static func eth1data(state: inout BeaconState, nextEpoch: EpochNumber) {
        if nextEpoch % EPOCHS_PER_ETH1_VOTING_PERIOD != 0 {
            return
        }

        for vote in state.eth1DataVotes {
            if vote.voteCount * 2 > EPOCHS_PER_ETH1_VOTING_PERIOD * SLOTS_PER_EPOCH {
                state.latestEth1Data = vote.eth1Data
            }
        }

        state.eth1DataVotes = [Eth1DataVote]()
    }

    private static func justification(
        state: inout BeaconState,
        previousEpoch: EpochNumber,
        currentEpoch: EpochNumber,
        previousTotalBalance: Gwei,
        previousEpochBoundaryAttestingBalance: Gwei,
        currentTotalBalance: Gwei,
        currentEpochBoundaryAttestingBalance: Gwei
    ) {
        var newJustifiedEpoch = state.justifiedEpoch
        state.justificationBitfield = state.justificationBitfield << 1

        if 3 * previousEpochBoundaryAttestingBalance >= 2 * previousTotalBalance {
            state.justificationBitfield |= 2
            newJustifiedEpoch = previousEpoch
        }

        if 3 * currentEpochBoundaryAttestingBalance >= 2 * currentTotalBalance {
            state.justificationBitfield |= 1
            newJustifiedEpoch = currentEpoch
        }

        if (state.justificationBitfield >> 1) % 8 == 0b111 && state.previousJustifiedEpoch == previousEpoch - 2 {
            state.finalizedEpoch = state.previousJustifiedEpoch
        }

        if (state.justificationBitfield >> 1) % 4 == 0b11 && state.previousJustifiedEpoch == previousEpoch - 1 {
            state.finalizedEpoch = state.previousJustifiedEpoch
        }

        if (state.justificationBitfield >> 0) % 8 == 0b111 && state.justifiedEpoch == previousEpoch - 1 {
            state.finalizedEpoch = state.justifiedEpoch
        }

        if (state.justificationBitfield >> 0) % 4 == 0b11 && state.justifiedEpoch == previousEpoch {
            state.finalizedEpoch = state.justifiedEpoch
        }

        state.previousJustifiedEpoch = state.justifiedEpoch
        state.justifiedEpoch = newJustifiedEpoch
    }

    private static func crosslink(
        state: inout BeaconState,
        previousEpoch: EpochNumber,
        currentEpoch: EpochNumber,
        nextEpoch: EpochNumber,
        currentEpochAttestations: [PendingAttestation],
        previousEpochAttestations: [PendingAttestation]
    ) {

        for slot in previousEpoch.startSlot()..<nextEpoch.startSlot() {
            let crosslinkCommitteesAtSlot = BeaconChain.getCrosslinkCommitteesAtSlot(state: state, slot: slot)

            for (_, (crosslinkCommittee, shard)) in crosslinkCommitteesAtSlot.enumerated() {

                // @todo clean up this pile of turd
                if 3 * totalAttestingBalance(state: state, committee: crosslinkCommittee, shard: shard, currentEpochAttestations: currentEpochAttestations, previousEpochAttestations: previousEpochAttestations) >= 2 * crosslinkCommittee.totalBalance(state: state) {
                    state.latestCrosslinks[Int(shard)] = Crosslink(
                        epoch: slot.toEpoch(),
                        shardBlockRoot: winningRoot(
                            state: state,
                            committee: crosslinkCommittee,
                            shard: shard,
                            currentEpochAttestations: currentEpochAttestations,
                            previousEpochAttestations: previousEpochAttestations
                        )
                    )
                }
            }
        }
    }

    private static func rewardsAndPenalties(
        state: inout BeaconState,
        previousEpoch: EpochNumber,
        currentEpoch: EpochNumber,
        nextEpoch: EpochNumber,
        previousTotalBalance: Gwei,
        totalBalance: UInt64,
        previousEpochJustifiedAttesterIndices: [ValidatorIndex],
        previousEpochJustifiedAttestingBalance: UInt64,
        previousEpochBoundaryAttesterIndices: [ValidatorIndex],
        previousEpochBoundaryAttestingBalance: UInt64,
        previousEpochHeadAttesterIndices: [ValidatorIndex],
        previousEpochHeadAttestingBalance: UInt64,
        previousEpochAttesterIndices: [ValidatorIndex],
        currentEpochAttestations: [PendingAttestation],
        previousEpochAttestations: [PendingAttestation]
    ) {
        let baseRewardQuotient = previousTotalBalance.sqrt() / BASE_REWARD_QUOTIENT

        let epochsSinceFinality = nextEpoch - state.finalizedEpoch

        let activeValidators = Set(state.validatorRegistry.activeIndices(epoch: currentEpoch))

        if epochsSinceFinality <= 4 {

            expectedFFGSource(
                state: &state,
                previousEpochJustifiedAttesterIndices: previousEpochJustifiedAttesterIndices,
                activeValidators: activeValidators,
                previousEpochJustifiedAttestingBalance: previousEpochJustifiedAttestingBalance,
                baseRewardQuotient: baseRewardQuotient,
                totalBalance: previousTotalBalance
            )

            expectedFFGTarget(
                state: &state,
                previousEpochBoundaryAttesterIndices: previousEpochBoundaryAttesterIndices,
                activeValidators: activeValidators,
                previousEpochBoundaryAttestingBalance: previousEpochBoundaryAttestingBalance,
                baseRewardQuotient: baseRewardQuotient,
                totalBalance: previousTotalBalance
            )

            expectedBeaconChainHead(
                state: &state,
                previousEpochHeadAttesterIndices: previousEpochHeadAttesterIndices,
                activeValidators: activeValidators,
                previousEpochHeadAttestingBalance: previousEpochHeadAttestingBalance,
                baseRewardQuotient: baseRewardQuotient,
                totalBalance: previousTotalBalance
            )

            for index in previousEpochAttesterIndices {
                state.validatorBalances[Int(index)] += baseReward(state: state, index: index, baseRewardQuotient: baseRewardQuotient) + MIN_ATTESTATION_INCLUSION_DELAY / inclusionDistance(state: state, index: index)
            }

        } else {
            deductInactivityBalance(
                state: &state,
                activeValidators: activeValidators,
                excluding: previousEpochJustifiedAttesterIndices,
                epochsSinceFinality: epochsSinceFinality,
                baseRewardQuotient: baseRewardQuotient
            )

            deductInactivityBalance(
                state: &state,
                activeValidators: activeValidators,
                excluding: previousEpochBoundaryAttesterIndices,
                epochsSinceFinality: epochsSinceFinality,
                baseRewardQuotient: baseRewardQuotient
            )

            activeValidators.subtracting(Set(previousEpochHeadAttesterIndices)).forEach({
                (index) in
                state.validatorBalances[Int(index)] -= baseReward(state: state, index: index, baseRewardQuotient: baseRewardQuotient)
            })

            activeValidators.forEach({
                index in
                if state.validatorRegistry[Int(index)].penalizedEpoch <= currentEpoch {
                    state.validatorBalances[Int(index)] -= 2 * inactivityPenalty(state: state, index: index, epochsSinceFinality: epochsSinceFinality, baseRewardQuotient: baseRewardQuotient) + baseReward(state: state, index: index, baseRewardQuotient: baseRewardQuotient)
                }
            })

            for index in previousEpochAttesterIndices {
                let base = baseReward(state: state, index: index, baseRewardQuotient: baseRewardQuotient)
                state.validatorBalances[Int(index)] -= base - base * MIN_ATTESTATION_INCLUSION_DELAY / inclusionDistance(state: state, index: index)
            }
        }

        for index in previousEpochAttesterIndices {
            let proposer = BeaconChain.getBeaconProposerIndex(
                state: state,
                slot: inclusionSlot(state: state, index: Int(index))
            )
            state.validatorBalances[Int(proposer)] += baseReward(state: state, index: index, baseRewardQuotient: baseRewardQuotient) / ATTESTATION_INCLUSION_REWARD_QUOTIENT
        }

        for slot in previousEpoch.startSlot()..<currentEpoch.startSlot() {
            let crosslinkCommitteesAtSlot = BeaconChain.getCrosslinkCommitteesAtSlot(state: state, slot: slot)

            for (_, (crosslinkCommittee, shard)) in crosslinkCommitteesAtSlot.enumerated() {

                let attestingValidators = self.attestingValidators(
                    state: state,
                    committee: crosslinkCommittee,
                    shard: shard,
                    currentEpochAttestations: currentEpochAttestations,
                    previousEpochAttestations: previousEpochAttestations
                )

                let totalBalance = crosslinkCommittee.totalBalance(state: state)
                let totalAttestingBalance = self.totalAttestingBalance(state: state, committee: crosslinkCommittee, shard: shard, currentEpochAttestations: previousEpochAttestations, previousEpochAttestations: previousEpochAttestations)

                for i in crosslinkCommittee {
                    if let _ = attestingValidators.firstIndex(of: i) {
                        state.validatorBalances[Int(i)] += baseReward(state: state, index: i, baseRewardQuotient: baseRewardQuotient) * totalAttestingBalance / totalBalance
                    } else {
                        state.validatorBalances[Int(i)] -= baseReward(state: state, index: i, baseRewardQuotient: baseRewardQuotient)
                    }
                }
            }
        }
    }

    static func processPenaltiesAndExit(state: inout BeaconState) {
        let currentEpoch = BeaconChain.getCurrentEpoch(state: state)
        let activeValidatorIndices = state.validatorRegistry.activeIndices(epoch: currentEpoch)

        let totalBalance = activeValidatorIndices.totalBalance(state: state)

        for (i, v) in state.validatorRegistry.enumerated() {
            if currentEpoch != v.penalizedEpoch + LATEST_SLASHED_EXIT_LENGTH / 2 {
                continue
            }

            let epochIndex = currentEpoch % LATEST_SLASHED_EXIT_LENGTH
            let totalAtStart = state.latestPenalizedBalances[Int((epochIndex + 1) % LATEST_SLASHED_EXIT_LENGTH)]
            let totalAtEnd = state.latestPenalizedBalances[Int(epochIndex)]
            let totalPenalties = totalAtEnd - totalAtStart
            let penalty = BeaconChain.getEffectiveBalance(state: state, index: ValidatorIndex(i)) * min(totalPenalties * 3, totalBalance) / totalBalance
            state.validatorBalances[i] -= penalty
        }

        var eligibleIndices = (0..<state.validatorRegistry.count).filter {
            let validator = state.validatorRegistry[$0]
            if validator.penalizedEpoch <= currentEpoch {
                let penalizedWithdrawalEpochs = LATEST_SLASHED_EXIT_LENGTH / 2
                return currentEpoch >= validator.penalizedEpoch + penalizedWithdrawalEpochs
            } else {
                return currentEpoch >= validator.penalizedEpoch + MIN_VALIDATOR_WITHDRAWAL_DELAY
            }
        }

        eligibleIndices.sort {
            state.validatorRegistry[$0].exitEpoch > state.validatorRegistry[$1].exitEpoch
        }

        var withdrawan = 0
        for i in eligibleIndices {
            BeaconChain.prepareValidatorForWithdrawal(state: &state, index: ValidatorIndex(i))
            withdrawan += 1
            if withdrawan >= MAX_EXIT_DEQUEUES_PER_EPOCH {
                break
            }
        }
    }

    static func updateValidatorRegistry(state: inout BeaconState) {
        let currentEpoch = BeaconChain.getCurrentEpoch(state: state)
        let activeValidatorIndices = state.validatorRegistry.activeIndices(epoch: currentEpoch)

        let totalBalance = activeValidatorIndices.totalBalance(state: state)
        let maxBalanceChurn = max(MAX_DEPOSIT_AMOUNT, totalBalance / (2 * MAX_BALANCE_CHURN_QUOTIENT))

        var balanceChurn = UInt64(0)
        for (i, v) in state.validatorRegistry.enumerated() {
            if v.activationEpoch > currentEpoch.entryExitEpoch() && state.validatorBalances[Int(i)] >= MAX_DEPOSIT_AMOUNT {
                balanceChurn += BeaconChain.getEffectiveBalance(state: state, index: ValidatorIndex(i))
                if balanceChurn > maxBalanceChurn {
                    break
                }

                BeaconChain.activateValidator(state: &state, index: ValidatorIndex(i), genesis: false)
            }
        }

        balanceChurn = 0
        for (i, v) in state.validatorRegistry.enumerated() {
            if v.exitEpoch > currentEpoch.entryExitEpoch() && v.statusFlags & StatusFlag.INITIATED_EXIT.rawValue == 1 {
                balanceChurn += BeaconChain.getEffectiveBalance(state: state, index: ValidatorIndex(i))
                if balanceChurn > maxBalanceChurn {
                    break
                }

                BeaconChain.exitValidator(state: &state, index: ValidatorIndex(i))
            }
        }

        state.validatorRegistryUpdateEpoch = currentEpoch
    }

    static func shufflingSeedData(state: inout BeaconState, nextEpoch: EpochNumber) {
        state.previousCalculationEpoch = state.currentCalculationEpoch
        state.previousEpochSeed = state.currentEpochSeed
        state.previousEpochStartShard = state.currentEpochStartShard
    }

    static func processEjections(state: inout BeaconState) {
        for i in state.validatorRegistry.activeIndices(epoch: BeaconChain.getCurrentEpoch(state: state)) {
            if state.validatorBalances[Int(i)] < EJECTION_BALANCE {
                BeaconChain.exitValidator(state: &state, index: i)
            }
        }
    }

    static func deductInactivityBalance(
        state: inout BeaconState,
        activeValidators: Set<ValidatorIndex>,
        excluding: [ValidatorIndex],
        epochsSinceFinality: UInt64,
        baseRewardQuotient: UInt64
    ) {
        activeValidators.subtracting(Set(excluding)).forEach {
            state.validatorBalances[Int($0)] -= inactivityPenalty(state: state, index: $0, epochsSinceFinality: epochsSinceFinality, baseRewardQuotient: baseRewardQuotient)
        }
    }

    static func expectedFFGSource(
        state: inout BeaconState,
        previousEpochJustifiedAttesterIndices: [ValidatorIndex],
        activeValidators: Set<ValidatorIndex>,
        previousEpochJustifiedAttestingBalance: UInt64,
        baseRewardQuotient: UInt64,
        totalBalance: UInt64
    ) {
        for index in previousEpochJustifiedAttesterIndices {
            state.validatorBalances[Int(index)] += baseReward(state: state, index: index, baseRewardQuotient: baseRewardQuotient) * previousEpochJustifiedAttestingBalance / totalBalance
        }

        activeValidators.subtracting(Set(previousEpochJustifiedAttesterIndices)).forEach({
            (index) in
            state.validatorBalances[Int(index)] -= baseReward(state: state, index: index, baseRewardQuotient: baseRewardQuotient)
        })
    }

    static func expectedFFGTarget(
        state: inout BeaconState,
        previousEpochBoundaryAttesterIndices: [ValidatorIndex],
        activeValidators: Set<ValidatorIndex>,
        previousEpochBoundaryAttestingBalance: UInt64,
        baseRewardQuotient: UInt64,
        totalBalance: UInt64
    ) {
        for index in previousEpochBoundaryAttesterIndices {
            state.validatorBalances[Int(index)] += baseReward(state: state, index: index, baseRewardQuotient: baseRewardQuotient) * previousEpochBoundaryAttestingBalance / totalBalance
        }

        activeValidators.subtracting(Set(previousEpochBoundaryAttesterIndices)).forEach({
            (index) in
            state.validatorBalances[Int(index)] -= baseReward(state: state, index: index, baseRewardQuotient: baseRewardQuotient)
        })
    }

    static func expectedBeaconChainHead(
        state: inout BeaconState,
        previousEpochHeadAttesterIndices: [ValidatorIndex],
        activeValidators: Set<ValidatorIndex>,
        previousEpochHeadAttestingBalance: UInt64,
        baseRewardQuotient: UInt64,
        totalBalance: UInt64
    ) {
        for index in previousEpochHeadAttesterIndices {
            state.validatorBalances[Int(index)] += baseReward(state: state, index: index, baseRewardQuotient: baseRewardQuotient) * previousEpochHeadAttestingBalance / totalBalance
        }

        activeValidators.subtracting(Set(previousEpochHeadAttesterIndices)).forEach({
            (index) in
            state.validatorBalances[Int(index)] -= baseReward(state: state, index: index, baseRewardQuotient: baseRewardQuotient)
        })
    }

    private static func baseReward(state: BeaconState, index: ValidatorIndex, baseRewardQuotient: UInt64) -> UInt64 {
        return BeaconChain.getEffectiveBalance(state: state, index: index) / baseRewardQuotient / 5
    }

    private static func inactivityPenalty(
        state: BeaconState,
        index: ValidatorIndex,
        epochsSinceFinality: UInt64,
        baseRewardQuotient: UInt64
    ) -> UInt64 {
        return baseReward(state: state, index: index, baseRewardQuotient: baseRewardQuotient) + BeaconChain.getEffectiveBalance(state: state, index: index) * epochsSinceFinality / INACTIVITY_PENALTY_QUOTIENT / 2
    }

    private static func attestingValidators(
        state: BeaconState,
        committee: [ValidatorIndex],
        shard: UInt64,
        currentEpochAttestations: [PendingAttestation],
        previousEpochAttestations: [PendingAttestation]
    ) -> [ValidatorIndex] {
        let root = winningRoot(
            state: state,
            committee: committee,
            shard: shard,
            currentEpochAttestations: currentEpochAttestations,
            previousEpochAttestations: previousEpochAttestations
        )

        return attestingValidatorIndices(
            state: state,
            committee: committee,
            shard: shard,
            shardBlockRoot: root,
            currentEpochAttestations: currentEpochAttestations,
            previousEpochAttestations: previousEpochAttestations
        )
    }

    private static func totalAttestingBalance(
        state: BeaconState,
        committee: [ValidatorIndex],
        shard: UInt64,
        currentEpochAttestations: [PendingAttestation],
        previousEpochAttestations: [PendingAttestation]
    ) -> UInt64 {
        return attestingValidators(
            state: state,
            committee: committee,
            shard: shard,
            currentEpochAttestations: currentEpochAttestations,
            previousEpochAttestations: previousEpochAttestations
        )
        .totalBalance(state: state)
    }

    private static func attestingValidatorIndices(
        state: BeaconState,
        committee: [ValidatorIndex],
        shard: UInt64,
        shardBlockRoot: Data,
        currentEpochAttestations: [PendingAttestation],
        previousEpochAttestations: [PendingAttestation]
    ) -> [ValidatorIndex] {
        return (currentEpochAttestations + previousEpochAttestations)
            .filter {
                $0.data.shard == shard && $0.data.shardBlockRoot == shardBlockRoot
            }
            .flatMap {
                return BeaconChain.getAttestationParticipants(
                    state: state,
                    attestationData: $0.data,
                    bitfield: $0.aggregationBitfield
                )
            }
    }

    private static func winningRoot(
        state: BeaconState,
        committee: [ValidatorIndex],
        shard: UInt64,
        currentEpochAttestations: [PendingAttestation],
        previousEpochAttestations: [PendingAttestation]
    ) -> Data {
        let candidateRoots = (currentEpochAttestations + previousEpochAttestations)
            .filter {
                $0.data.shard == shard
            }
            .map {
                $0.data.shardBlockRoot
            }

        var winnerRoot = Data(count: 0)
        var winnerBalance = UInt64(0)
        for root in candidateRoots {
            let indices = attestingValidatorIndices(
                state: state,
                committee: committee,
                shard: shard,
                shardBlockRoot: root,
                currentEpochAttestations: currentEpochAttestations,
                previousEpochAttestations: previousEpochAttestations
            )

            let rootBalance = indices.totalBalance(state: state)

            if rootBalance > winnerBalance || (rootBalance == winnerBalance && root < winnerRoot) {
                winnerBalance = rootBalance
                winnerRoot = root
            }
        }

        return winnerRoot
    }

    private static func inclusionDistance(state: BeaconState, index: ValidatorIndex) -> UInt64 {
        for a in state.latestAttestations {
            let participated = BeaconChain.getAttestationParticipants(state: state, attestationData: a.data, bitfield: a.aggregationBitfield)

            for i in participated {
                if index == i {
                    return a.inclusionSlot - a.data.slot
                }
            }
        }

        return 0
    }

    private static func inclusionSlot(state: BeaconState, index: Int) -> UInt64 {
        for a in state.latestAttestations {
            let participated = BeaconChain.getAttestationParticipants(state: state, attestationData: a.data, bitfield: a.aggregationBitfield)

            for i in participated {
                if index == i {
                    return a.inclusionSlot
                }
            }
        }

        return 0
    }
}

extension StateTransition {

    static func processStateRoot(state: BeaconState) {
        // @todo Verify block.state_root == hash_tree_root(state) if there exists a block for the slot being processed.
    }

}
