import Foundation

class Attestations: BlockTransitions {

    static func transition(state: inout BeaconState, block: BeaconBlock) {
        assert(block.body.attestations.count <= MAX_ATTESTATIONS)

        for attestation in block.body.attestations {
            assert(attestation.data.slot >= GENESIS_SLOT)
            assert(attestation.data.slot + MIN_ATTESTATION_INCLUSION_DELAY <= state.slot)
            assert(state.slot < attestation.data.slot + SLOTS_PER_EPOCH)

            let e = (attestation.data.slot + 1).toEpoch() >= BeaconChain.getCurrentEpoch(state: state) ? state.justifiedEpoch : state.previousJustifiedEpoch
            assert(attestation.data.justifiedEpoch == e)
            assert(attestation.data.justifiedBlockRoot == BeaconChain.getBlockRoot(state: state, slot: attestation.data.justifiedEpoch.startSlot()))

            assert(
                state.latestCrosslinks[Int(attestation.data.shard)] == attestation.data.latestCrosslink ||
                    state.latestCrosslinks[Int(attestation.data.shard)] == Crosslink(
                        epoch: attestation.data.slot.toEpoch(),
                        crosslinkDataRoot: attestation.data.crosslinkDataRoot
                    )
            )

            assert(attestation.custodyBitfield == Data(repeating: 0, count: 32))
            assert(attestation.aggregationBitfield != Data(repeating: 0, count: 32))

            let crosslinkCommittee = BeaconChain.crosslinkCommittees(state, at: attestation.data.slot).filter {
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
                    domain: state.fork.domain(epoch: attestation.data.slot.toEpoch(), type: .attestation)
                )
            )

            assert(attestation.data.crosslinkDataRoot == ZERO_HASH) // @todo remove in phase 1

            state.latestAttestations.append(
                PendingAttestation(
                    aggregationBitfield: attestation.aggregationBitfield, data: attestation.data,
                    custodyBitfield: attestation.custodyBitfield,
                    inclusionSlot: state.slot
                )
            )
        }
    }
}
