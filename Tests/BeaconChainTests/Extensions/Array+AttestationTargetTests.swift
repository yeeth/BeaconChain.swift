import XCTest
@testable import BeaconChain

final class ArrayAttestationTargetTests: XCTestCase {

    func testVotes() {
        var state = BeaconChain.genesisState(
            genesisTime: 10,
            latestEth1Data: Eth1Data(depositRoot: Data(count: 32), blockHash: Data(count: 32)),
            depositLength: 0
        )

        state.validatorBalances.append(32000000000)
        state.validatorBalances.append(32000000000)
        state.validatorBalances.append(32000000000)

        let block = BeaconBlock(
            slot: GENESIS_SLOT,
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

        let store = MockStore()

        var badBlock = block
        badBlock.signature = EMPTY_SIGNATURE

        var targets = [AttestationTarget]()
        targets.append((0, block))
        targets.append((1, badBlock))
        targets.append((2, block))

        XCTAssertEqual(64, targets.votes(store: store, state: state, block: block))
    }

}
