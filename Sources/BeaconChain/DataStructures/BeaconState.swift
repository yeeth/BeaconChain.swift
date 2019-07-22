import Foundation

struct BeaconState {
    let genesisTime: UInt64
    let slot: Slot
    let fork: Fork
    let latestBlockHeader: BeaconBlockHeader
    let blockRoots: [Hash]
    let stateRoots: [Hash]
    let historicalRoots: [Hash]
    let eth1Data: Eth1Data
    let eth1DataVotes: [Eth1Data]
    let eth1DepositIndex: UInt64
    let validators: [Validator]
    let balances: [Gwei]
    let startShard: Shard
    let randaoMixes: [Hash]
    let activeIndexRoots: [Hash]
    let compactCommitteesRoots: [Hash]
    let slashings: [Gwei]
    let previousEpochAttestations: [PendingAttestation]
    let currentEpochAttestations: [PendingAttestation]
    let previousCrosslinks: [Crosslink]
    let currentCrosslinks: [Crosslink]
    let justificationBits: [Bool]
    let previousJustifiedCheckpoint: Checkpoint
    let currentJustifiedCheckpoint: Checkpoint
    let finalizedCheckpoint: Checkpoint

    /// Check if `indexed_attestation` has valid indices and signature.
    ///
    /// - Parameters:
    ///     - indexedAttestation: The attestation to check.
    func isValid(indexedAttestation attestation: IndexedAttestation) -> Bool {

        let bit0Indices = attestation.custodyBit0Indices
        let bit1Indices = attestation.custodyBit1Indices

        if bit1Indices.count == 0 {
            return false
        }

        if !(bit0Indices.count + bit1Indices.count <= MAX_VALIDATORS_PER_COMMITTEE) {
            return false
        }

        if Set(bit0Indices).intersection(Set(bit1Indices)).count != 0 {
            return false
        }

        if bit0Indices != bit0Indices.sorted() || bit1Indices != bit1Indices.sorted() {
            return false
        }

        return BLS.verify(
                pubkeys: BLS.aggregate(
                        pubkeys: bit0Indices.map { (i) in
                            return validators[Int(i)].pubkey
                        }
                ),
                BLS.aggregate(
                        pubkeys: bit1Indices.map { (i) in
                            return validators[Int(i)].pubkey
                        }
                ),
                hashes: [
                    SSZ.hashTreeRoot(AttestationDataAndCustodyBit(data: attestation.data, custodyBit: false)),
                    SSZ.hashTreeRoot(AttestationDataAndCustodyBit(data: attestation.data, custodyBit: true)),
                ],
                signature: attestation.signature,
                domain: getDomain(type: DomainType.attestation, epoch: attestation.data.target.epoch)
        )
    }

    func getDomain(type: DomainType, epoch: Epoch) -> Domain {

    }
}
