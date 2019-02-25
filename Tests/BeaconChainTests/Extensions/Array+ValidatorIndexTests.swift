import XCTest
@testable import BeaconChain

final class ArrayValidatorIndexTests: XCTestCase {

    func testTotalBalance() {
        var state = BeaconChain.genesisState(
            genesisTime: 10,
            latestEth1Data: Eth1Data(depositRoot: Data(count: 32), blockHash: Data(count: 32)),
            depositLength: 0
        )

        // @todo make dynamic
        state.validatorBalances.append(10)
        state.validatorBalances.append(10)

        XCTAssertEqual([ValidatorIndex(0), 1].totalBalance(state: state), 20)
    }

}