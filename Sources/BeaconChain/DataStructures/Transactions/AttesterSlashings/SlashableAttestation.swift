import Foundation

struct SlashableAttestation {
    let validatorIndices: [UInt64]
    let data: AttestationData
    let custodyBitfield: Data
    let aggregateSignature: Data

    func verify(state: BeaconState) -> Bool {
        if custodyBitfield != Data(repeating: 0, count: custodyBitfield.count) {
            return false
        }

        if validatorIndices.count == 0 {
            return false
        }

        for i in 0..<(validatorIndices.count - 1) {
            if validatorIndices[i] >= validatorIndices[i + 1] {
                return false
            }
        }

        if !BeaconChain.verifyBitfield(bitfield: custodyBitfield, committeeSize: validatorIndices.count) {
            return false
        }

        if validatorIndices.count > MAX_INDICES_PER_SLASHABLE_VOTE {
            return false
        }

        var custodyBit0Indices = [UInt64]()
        var custodyBit1Indices = [UInt64]()

        for (i, validatorIndex) in validatorIndices.enumerated() {
            if BeaconChain.getBitfieldBit(bitfield: custodyBitfield, i: i) == 0b0 {
                custodyBit0Indices.append(validatorIndex)
            } else {
                custodyBit1Indices.append(validatorIndex)
            }
        }

        return BLS.verify(
            pubkeys: [
                BLS.aggregate(
                    pubkeys: custodyBit0Indices.map { (i) in
                        return state.validatorRegistry[Int(i)].pubkey
                    }
                ),
                BLS.aggregate(
                    pubkeys: custodyBit1Indices.map { (i) in
                        return state.validatorRegistry[Int(i)].pubkey
                    }
                )
            ],
            messages: [
                BeaconChain.hashTreeRoot(AttestationDataAndCustodyBit(data: data, custodyBit: false)),
                BeaconChain.hashTreeRoot(AttestationDataAndCustodyBit(data: data, custodyBit: true)),
            ],
            signature: aggregateSignature,
            domain: BeaconChain.getDomain(fork: state.fork, epoch: data.slot.toEpoch(), domainType: Domain.ATTESTATION)
        )
    }
}
