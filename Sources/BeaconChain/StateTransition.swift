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
        casperSlashings(state: &state, block: block)
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
        let votes = state.eth1DataVotes.enumerated()
        for (i, vote) in votes {
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

    static func casperSlashings(state: inout BeaconState, block: BeaconBlock) {
        assert(block.body.casperSlashings.count <= MAX_CASPER_SLASHINGS)

        for casperSlashing in block.body.casperSlashings {
            let slashableVoteData1 = casperSlashing.slashableVoteData1
            let slashableVoteData2 = casperSlashing.slashableVoteData2

            let slashableVoteData1Indices = slashableVoteData1.custodyBit0Indices + slashableVoteData1.custodyBit1Indices
            let slashableVoteData2Indices = slashableVoteData2.custodyBit0Indices + slashableVoteData2.custodyBit1Indices

            let intersection = Set(slashableVoteData1Indices).intersection(Set(slashableVoteData2Indices))

            assert(intersection.count > 1)

            assert(slashableVoteData1.data != slashableVoteData2.data)
            assert(
                BeaconChain.isDoubleVote(slashableVoteData1.data, slashableVoteData2.data)
                || BeaconChain.isSurroundVote(slashableVoteData1.data, slashableVoteData2.data)
            )

            assert(BeaconChain.verifySlashableVoteData(state: state, data: slashableVoteData1))
            assert(BeaconChain.verifySlashableVoteData(state: state, data: slashableVoteData2))

            for i in intersection {
                if state.validatorRegistry[Int(i)].penalizedEpoch <= BeaconChain.getCurrentEpoch(state: state) {
                    continue
                }

                BeaconChain.penalizeValidator(state: &state, index: i)
            }
        }
    }

    static func attestations(state: inout BeaconState, block: BeaconBlock) {
        assert(block.body.attestations.count <= MAX_ATTESTATIONS)

        for attestation in block.body.attestations {
            assert(attestation.data.slot + MIN_ATTESTATION_INCLUSION_DELAY <= state.slot)
            assert(attestation.data.slot + EPOCH_LENGTH >= state.slot)

            let e = attestation.data.justifiedEpoch >= BeaconChain.getCurrentEpoch(state: state) ? state.justifiedEpoch : state.previousJustifiedEpoch
            assert(attestation.data.justifiedEpoch == e)
            assert(attestation.data.justifiedBlockRoot == BeaconChain.getBlockRoot(state: state, slot: BeaconChain.getEpochStartSlot(attestation.data.justifiedEpoch)))

            let shardBlockRoot = state.latestCrosslinks[Int(attestation.data.shard)].shardBlockRoot
            assert(attestation.data.latestCrosslinkRoot == shardBlockRoot || attestation.data.shardBlockRoot == shardBlockRoot)

            let participants = BeaconChain.getAttestationParticipants(
                state: state,
                attestationData: attestation.data,
                aggregationBitfield: attestation.aggregationBitfield
            )

            let groupPublicKey = BLS.aggregate(pubkeys: participants.map { return state.validatorRegistry[Int($0)].pubkey })

            assert(
                BLS.verify(
                    pubkey: groupPublicKey,
                    message: BeaconChain.hashTreeRoot(AttestationDataAndCustodyBit(data: attestation.data, custodyBit: false)),
                    signature: attestation.aggregateSignature,
                    domain: BeaconChain.getDomain(
                        fork: state.fork,
                        epoch: BeaconChain.slotToEpoch(attestation.data.slot),
                        domainType: Domain.ATTESTATION
                    )
                )
            )

            assert(attestation.data.shardBlockRoot == ZERO_HASH) // @todo remove in phase 1

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
        assert(block.body.exits.count <= MAX_EXITS)

        for exit in block.body.exits {
            let validator = state.validatorRegistry[Int(exit.validatorIndex)]

            let epoch = BeaconChain.getCurrentEpoch(state: state)
            assert(validator.exitEpoch > BeaconChain.getEntryExitEpoch(epoch))
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
            if index / (2**i) % 2 == 1 {
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
        assert(state.slot + 1 % EPOCH_LENGTH == 0) // @todo not sure if this should be here

        let currentEpoch = BeaconChain.getCurrentEpoch(state: state)
        let previousEpoch = currentEpoch > GENESIS_EPOCH ? currentEpoch - 1 : currentEpoch
        let nextEpoch = currentEpoch + 1

        let currentTotalBalance = totalBalance(state: state, validators: BeaconChain.getActiveValidatorIndices(validators: state.validatorRegistry, epoch: currentEpoch))

        let currentEpochAttestations = state.latestAttestations.filter {
            currentEpoch == BeaconChain.slotToEpoch($0.data.slot)
        }

        let currentEpochBoundryAttestations = currentEpochAttestations.filter {
            $0.data.epochBoundaryRoot == BeaconChain.getBlockRoot(state: state, slot: BeaconChain.getEpochStartSlot(currentEpoch))
                && $0.data.justifiedEpoch == state.justifiedEpoch
        }

        let currentEpochBoundaryAttesterIndices = currentEpochAttestations.flatMap {
            return BeaconChain.getAttestationParticipants(state: state, attestationData: $0.data, aggregationBitfield: $0.aggregationBitfield)
        }

        let currentEpochBoundaryAttestingBalance = totalBalance(state: state, validators: currentEpochBoundaryAttesterIndices)

        let previousTotalBalance = totalBalance(
            state: state,
            validators: BeaconChain.getActiveValidatorIndices(validators: state.validatorRegistry, epoch: previousEpoch)
        )

        let previousEpochAttestations = state.latestAttestations.filter {
            previousEpoch == BeaconChain.slotToEpoch($0.data.slot)
        }

        let previousEpochAttesterIndices = previousEpochAttestations.flatMap {
            return BeaconChain.getAttestationParticipants(state: state, attestationData: $0.data, aggregationBitfield: $0.aggregationBitfield)
        }

        let previousEpochJustifiedAttestations = (currentEpochAttestations + previousEpochAttestations)
            .filter { $0.data.justifiedEpoch == state.previousJustifiedEpoch }

        let previousEpochJustifiedAttesterIndices = previousEpochJustifiedAttestations.flatMap {
            return BeaconChain.getAttestationParticipants(state: state, attestationData: $0.data, aggregationBitfield: $0.aggregationBitfield)
        }

        let previousEpochJustifiedAttestingBalance = totalBalance(state: state, validators: previousEpochJustifiedAttesterIndices)

        let previousEpochBoundaryAttestations = previousEpochJustifiedAttestations.filter {
            $0.data.epochBoundaryRoot == BeaconChain.getBlockRoot(state: state, slot: BeaconChain.getEpochStartSlot(previousEpoch))
        }

        let previousEpochBoundaryAttesterIndices = previousEpochBoundaryAttestations.flatMap {
            return BeaconChain.getAttestationParticipants(state: state, attestationData: $0.data, aggregationBitfield: $0.aggregationBitfield)
        }

        let previousEpochBoundaryAttestingBalance = totalBalance(state: state, validators: previousEpochBoundaryAttesterIndices)

        let previousEpochHeadAttestations = previousEpochAttestations.filter {
            $0.data.beaconBlockRoot == BeaconChain.getBlockRoot(state: state, slot: $0.data.slot)
        }

        let previousEpochHeadAttesterIndices = previousEpochHeadAttestations.flatMap {
            return BeaconChain.getAttestationParticipants(state: state, attestationData: $0.data, aggregationBitfield: $0.aggregationBitfield)
        }

        let previousEpochHeadAttestingBalance = totalBalance(state: state, validators: previousEpochHeadAttesterIndices)
    }

    private static func attestingValidators(
        state: BeaconState,
        committee: [Int],
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
        committee: [Int],
        shard: UInt64,
        currentEpochAttestations: [PendingAttestation],
        previousEpochAttestations: [PendingAttestation]
    ) -> UInt64 {
        return totalBalance(
            state: state,
            validators: attestingValidators(
                state: state,
                committee: committee,
                shard: shard,
                currentEpochAttestations: currentEpochAttestations,
                previousEpochAttestations: previousEpochAttestations
            )
        )
    }

    private static func totalBalance(state: BeaconState, validators: [ValidatorIndex]) -> UInt64 {
        return validators.map { return BeaconChain.getEffectiveBalance(state: state, index: $0) }
            .reduce(0, +)
    }

    private static func attestingValidatorIndices(
        state: BeaconState,
        committee: [Int],
        shard: UInt64,
        shardBlockRoot: Data,
        currentEpochAttestations: [PendingAttestation],
        previousEpochAttestations: [PendingAttestation]
    ) -> [ValidatorIndex] {
        return (currentEpochAttestations + previousEpochAttestations)
            .filter { $0.data.shard == shard && $0.data.shardBlockRoot == shardBlockRoot }
            .flatMap {
                return BeaconChain.getAttestationParticipants(
                    state: state,
                    attestationData: $0.data,
                    aggregationBitfield: $0.aggregationBitfield
                )
            }
    }

    private static func winningRoot(
        state: BeaconState,
        committee: [Int],
        shard: UInt64,
        currentEpochAttestations: [PendingAttestation],
        previousEpochAttestations: [PendingAttestation]
    ) -> Data {
        let candidateRoots = (currentEpochAttestations + previousEpochAttestations)
            .filter { $0.data.shard == shard }
            .map { $0.data.shardBlockRoot }

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

            let rootBalance = self.totalBalance(state: state, validators: indices)

            if rootBalance > winnerBalance || (rootBalance == winnerBalance && root < winnerRoot) {
                winnerBalance = rootBalance
                winnerRoot = root
            }
        }

        return winnerRoot
    }
}
