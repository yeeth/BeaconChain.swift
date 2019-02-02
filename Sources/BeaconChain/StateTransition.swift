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
        assert(block.body.proposerSlashings.count <= MAX_CASPER_SLASHINGS)

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
}
