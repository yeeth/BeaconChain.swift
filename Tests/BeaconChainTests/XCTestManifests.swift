import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BeaconChainTests.allTests),
        testCase(ArrayTests.allTests),
        testCase(ArrayValidatorIndexTests.allTests),
        testCase(ArrayValidatorTests.allTests),
        testCase(SlotTests.allTests),
        testCase(EpochTests.allTests),
        testCase(ValidatorTests.allTests),
        testCase(BeaconStateTests.allTests),
        testCase(ForkTests.allTests),
//        testCase(StateTransitionTests.allTests)
    ]
}
#endif
