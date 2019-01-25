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

    func testIntegerSquareRoot() {
        let numbers = [(20, 4), (200, 14), (1987, 44), (34989843, 5915), (97282, 311)]

        for num in numbers {
            XCTAssertEqual(num.1, BeaconChain.integerSquareRoot(n: num.0))
        }
    }

    func testIsSurroundVote() {
        let data = AttestationData(
            slot: 192,
            shard: 0,
            beaconBlockRoot: Data(count: 32),
            epochBoundryRoot: Data(count: 32),
            shardBlockRoot: Data(count: 32),
            latestCrosslinkRoot: Data(count: 32),
            justifiedSlot: 0,
            justifiedBlockRoot: Data(count: 32)
        )

        XCTAssertFalse(BeaconChain.isSurroundVote(first: data, second: data))
        XCTAssertTrue(
            BeaconChain.isSurroundVote(
                first: data,
                second: AttestationData(
                    slot: 128,
                    shard: 0,
                    beaconBlockRoot: Data(count: 32),
                    epochBoundryRoot: Data(count: 32),
                    shardBlockRoot: Data(count: 32),
                    latestCrosslinkRoot: Data(count: 32),
                    justifiedSlot: 64,
                    justifiedBlockRoot: Data(count: 32)
                )
            )
        )
    }

    func testGetDomainVersion() {
        let data = Fork(previousVersion: 2, currentVersion: 3, slot: 10)
        let constant = 2**32

        XCTAssertEqual(
            BeaconChain.getDomain(data: data, slot: 9, domainType: Domain.PROPOSAL),
            (2*constant)+2
        )

        XCTAssertEqual(
            BeaconChain.getDomain(data: data, slot: 11, domainType: Domain.EXIT),
            (3*constant)+3
        )
    }
}
