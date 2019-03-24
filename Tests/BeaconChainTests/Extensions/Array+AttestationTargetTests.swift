import XCTest
@testable import BeaconChain

final class ArrayAttestationTargetTests: XCTestCase {

    func testVotes() {
        var state = BeaconChain.genesisState(
            genesisTime: 10,
            latestEth1Data: Eth1Data(depositRoot: Data(count: 32), blockHash: Data(count: 32)),
            depositLength: 0
        )

        state.validatorBalances.append(2000000000)
        state.validatorBalances.append(2000000000)

        let store = MockStore()
        store.ancestor = BeaconBlock(
            slot: 0,
            parentRoot: ZERO_HASH,
            stateRoot: ZERO_HASH,
            randaoReveal: ZERO_HASH,
            eth1Data: state.latestEth1Data,
            body: BeaconBlockBody(
                proposerSlashings: [ProposerSlashing](),
                attesterSlashings: [AttesterSlashing](),
                attestations: [Attestation](),
                deposits: [Deposit](),
                voluntaryExits: [VoluntaryExit](),
                transfers: [Transfer]()
            ),
            signature: ZERO_HASH
        )

        var badBlock = store.ancestor
        badBlock?.signature = EMPTY_SIGNATURE

        var targets = [AttestationTarget]()
        targets.append((0, store.ancestor))
        targets.append((1, badBlock!))

        XCTAssertEqual(2, targets.votes(store: store, state: state, block: store.ancestor))
    }

}