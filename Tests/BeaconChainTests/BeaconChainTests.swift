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

    func testInitiateValidatorExit() {
        var state = BeaconChain.genesisState(
            genesisTime: 0,
            latestEth1Data: Eth1Data(depositRoot: Data(count: 32), blockHash: Data(count: 32)),
            depositLength: 0
        )

        for _ in 0..<3 {
            state.validatorRegistry.append(
                Validator(
                    pubkey: Data(count: 32),
                    withdrawalCredentials: Data(count: 32),
                    activationEpoch: 0,
                    exitEpoch: 0,
                    withdrawableEpoch: 0,
                    initiatedExit: false,
                    slashed: false
                )
            )
        }

        BeaconChain.initiateValidatorExit(state: &state, index: 2)

        XCTAssertFalse(state.validatorRegistry[0].initiatedExit)
        XCTAssertTrue(state.validatorRegistry[2].initiatedExit)
    }

    func testActivateValidator() {
        var state = BeaconChain.genesisState(
            genesisTime: 0,
            latestEth1Data: Eth1Data(depositRoot: Data(count: 32), blockHash: Data(count: 32)),
            depositLength: 0
        )

        state.slot = 10
        state.validatorRegistry.append(
            Validator(
                pubkey: Data(count: 32),
                withdrawalCredentials: Data(count: 32),
                activationEpoch: 0,
                exitEpoch: 0,
                withdrawableEpoch: 0,
                initiatedExit: false,
                slashed: false
            )
        )

        BeaconChain.activateValidator(state: &state, index: 0, genesis: false)
        XCTAssertEqual(state.validatorRegistry[0].activationEpoch, 5)
    }

//    func testExitValidator() {
//        var state = BeaconChain.genesisState(
//            genesisTime: 0,
//            latestEth1Data: Eth1Data(depositRoot: Data(count: 32), blockHash: Data(count: 32))
//        )
//
//        state.slot = 100
//        state.validatorRegistry.append(
//            Validator(
//                pubkey: Data(count: 32),
//                withdrawalCredentials: Data(count: 32),
//                activationEpoch: 0,
//                exitEpoch: 0,
//                withdrawalEpoch: 0,
//                penalizedEpoch: 0,
//                exitCount: 0,
//                statusFlags: 0,
//                latestCustodyReseedSlot: 0,
//                penultimateCustodyReseedSlot: 0
//            )
//        )
//
//        BeaconChain.exitValidator(state: &state, index: 0)
//        XCTAssertEqual(state.validatorRegistry[0].exitEpoch, 1 + ENTRY_EXIT_DELAY)
//        XCTAssertEqual(state.validatorRegistry[0].exitCount, 1)
//    }
}
