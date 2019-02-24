import XCTest
@testable import BeaconChain

final class BeaconChainTests: XCTestCase {

    func testGetForkVersion() {
        let fork = Fork(previousVersion: 10, currentVersion: 20, epoch: 1)
        XCTAssertEqual(10, BeaconChain.getForkVersion(fork: fork, epoch: 0))
        XCTAssertEqual(20, BeaconChain.getForkVersion(fork: fork, epoch: 2))
    }

    func testIsDoubleVote() {
        let dummy = Data(count: 1)
        let attestation = AttestationData(
            slot: 128,
            shard: 0,
            beaconBlockRoot: dummy,
            epochBoundaryRoot: dummy,
            shardBlockRoot: dummy,
            latestCrosslink: Crosslink(epoch: 0, shardBlockRoot: dummy),
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

    func testGetDomainVersion() {
        let data = Fork(previousVersion: 2, currentVersion: 3, epoch: 10)
        let constant = 2**32

        XCTAssertEqual(
            BeaconChain.getDomain(fork: data, epoch: 9, domainType: Domain.PROPOSAL),
            EpochNumber((2*constant)+2)
        )

        XCTAssertEqual(
            BeaconChain.getDomain(fork: data, epoch: 11, domainType: Domain.EXIT),
            EpochNumber((3*constant)+3)
        )
    }

    func testInitiateValidatorExit() {
        var state = BeaconChain.genesisState(
            genesisTime: 0,
            latestEth1Data: Eth1Data(depositRoot: Data(count: 32), blockHash: Data(count: 32))
        )

        for _ in 0..<3 {
            state.validatorRegistry.append(
                Validator(
                    pubkey: Data(count: 32),
                    withdrawalCredentials: Data(count: 32),
                    activationEpoch: 0,
                    exitEpoch: 0,
                    withdrawableEpoch: 0,
                    slashedEpoch: 0,
                    statusFlags: 0
                )
            )
        }

        BeaconChain.initiateValidatorExit(state: &state, index: 2)

        XCTAssertEqual(state.validatorRegistry[0].statusFlags, 0)
        XCTAssertEqual(state.validatorRegistry[2].statusFlags, StatusFlag.INITIATED_EXIT.rawValue)
    }

    func testActivateValidator() {
        var state = BeaconChain.genesisState(
            genesisTime: 0,
            latestEth1Data: Eth1Data(depositRoot: Data(count: 32), blockHash: Data(count: 32))
        )

        state.slot = 10
        state.validatorRegistry.append(
            Validator(
                pubkey: Data(count: 32),
                withdrawalCredentials: Data(count: 32),
                activationEpoch: 0,
                exitEpoch: 0,
                withdrawableEpoch: 0,
                slashedEpoch: 0,
                statusFlags: 0
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
