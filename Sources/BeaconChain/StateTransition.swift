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
}
