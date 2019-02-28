import XCTest
@testable import BeaconChain

final class BeaconChainTests: XCTestCase {

    func testIsDoubleVote() {
        let dummy = Data(count: 1)
        let attestation = AttestationData(
            slot: 128,
            shard: 0,
            beaconBlockRoot: dummy,
            epochBoundaryRoot: dummy,
            crosslinkDataRoot: dummy,
            latestCrosslink: Crosslink(epoch: 0, crosslinkDataRoot: dummy),
            justifiedEpoch: 0,
            justifiedBlockRoot: dummy
        )

        XCTAssert(BeaconChain.isDoubleVote(attestation, attestation))
    }

    func testIntegerSquareRoot() {
        let numbers = [(UInt64(20), UInt64(4)), (200, 14), (1987, 44), (34989843, 5915), (97282, 311)]

        for num in numbers {
            XCTAssertEqual(num.1, num.0.sqrt())
        }
    }

//    func testIsSurroundVote() {
//        let data = AttestationData(
//            slot: 192,
//            shard: 0,
//            beaconBlockRoot: Data(count: 32),
//            epochBoundaryRoot: Data(count: 32),
//            shardBlockRoot: Data(count: 32),
//            latestCrosslinkRoot: Data(count: 32),
//            justifiedEpoch: 0,
//            justifiedBlockRoot: Data(count: 32)
//        )
//
//        XCTAssertFalse(BeaconChain.isSurroundVote(data, data))
//        XCTAssertTrue(
//            BeaconChain.isSurroundVote(
//                data,
//                AttestationData(
//                    slot: 128,
//                    shard: 0,
//                    beaconBlockRoot: Data(count: 32),
//                    epochBoundaryRoot: Data(count: 32),
//                    shardBlockRoot: Data(count: 32),
//                    latestCrosslinkRoot: Data(count: 32),
//                    justifiedEpoch: 64,
//                    justifiedBlockRoot: Data(count: 32)
//                )
//            )
//        )
//    }
}
