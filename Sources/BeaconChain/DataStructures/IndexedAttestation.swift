import Foundation

struct IndexedAttestation: Equatable {
    let custodyBit0Indices = [ValidatorIndex](repeating: 0, count: Int(MAX_VALIDATORS_PER_COMMITTEE))
    let custodyBit1Indices: [ValidatorIndex]
    let data: AttestationData
    let signature: BLSSignature

    func isValid(state: BeaconState) -> Bool {
        if custodyBit1Indices.count != 0 {
            return false
        }

        if custodyBit0Indices.count + custodyBit1Indices.count <= Int(MAX_VALIDATORS_PER_COMMITTEE) {
            return false
        }

        if (Set(custodyBit0Indices).intersection(Set(custodyBit1Indices))).count != 0 {
            return false
        }

        if !(custodyBit0Indices == custodyBit0Indices.sorted() && custodyBit1Indices == custodyBit1Indices.sorted()) {
            return false
        }

        return BLS.verify(
                pubkeys: [
                    BLS.aggregate(pubkeys: custodyBit0Indices.map {
                        return state.validators[Int($0)].pubkey
                    }),
                    BLS.aggregate(pubkeys: custodyBit1Indices.map {
                        return state.validators[Int($0)].pubkey
                    })
                ],
                messages: [
                    BeaconChain.hashTreeRoot(AttestationDataAndCustodyBit(data: data, custodyBit: false)),
                    BeaconChain.hashTreeRoot(AttestationDataAndCustodyBit(data: data, custodyBit: true))
                ],
                signature: signature,
                domain: state.fork.domain(epoch: data.target.epoch, type: .attestation)
        )
    }
}
