import XCTest
@testable import BeaconChain

final class BeaconChainTests: XCTestCase {

    func testGetForkVersion() {
        let fork = Fork(previousVersion: 10, currentVersion: 20, slot: 1)
        XCTAssertEqual(10, BeaconChain.getForkVersion(data: fork, slot: 0))
        XCTAssertEqual(20, BeaconChain.getForkVersion(data: fork, slot: 2))
    }

    func testIsDoubleVote() {
        let dummy = Data(count: 1)
        let attestation = AttestationData(
            slot: 128,
            shard: 0,
            beaconBlockRoot: dummy,
            epochBoundryRoot: dummy,
            shardBlockRoot: dummy,
            latestCrosslinkRoot: dummy,
            justifiedSlot: 0,
            justifiedBlockRoot: dummy
        )

        XCTAssert(BeaconChain.isDoubleVote(first: attestation, second: attestation))
    }
}
