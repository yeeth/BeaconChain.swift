import Foundation

class Transfers: BlockTransitions {

    static func transition(state: inout BeaconState, block: BeaconBlock) {
        assert(block.body.transfers.count <= MAX_TRANSFERS)

        for transfer in block.body.transfers {
            assert(state.validatorBalances[Int(transfer.from)] >= transfer.amount)
            assert(state.validatorBalances[Int(transfer.from)] >= transfer.fee)
            assert(
                state.validatorBalances[Int(transfer.from)] == transfer.amount + transfer.fee
                    || state.validatorBalances[Int(transfer.from)] >= transfer.amount + transfer.fee + MIN_DEPOSIT_AMOUNT
            )

            assert(state.slot == transfer.slot)
            assert(
                BeaconChain.getCurrentEpoch(state: state) >= state.validatorRegistry[Int(transfer.from)].withdrawableEpoch
                    || state.validatorRegistry[Int(transfer.from)].activationEpoch == FAR_FUTURE_EPOCH
            )
            assert(state.validatorRegistry[Int(transfer.from)].withdrawalCredentials == BLS_WITHDRAWAL_PREFIX_BYTE + BeaconChain.hash(transfer.pubkey).suffix(from: 1))

            assert(
                BLS.verify(
                    pubkey: transfer.pubkey,
                    message: BeaconChain.signedRoot(transfer, field: "signature"),
                    signature: transfer.signature,
                    domain: state.fork.domain(epoch: transfer.slot.toEpoch(), type: .transfer)
                )
            )

            state.validatorBalances[Int(transfer.from)] -= transfer.amount + transfer.fee
            state.validatorBalances[Int(transfer.to)] += transfer.amount
            state.validatorBalances[Int(BeaconChain.getBeaconProposerIndex(state: state, slot: state.slot))] += transfer.fee
        }
    }
}
