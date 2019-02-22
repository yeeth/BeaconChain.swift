import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BeaconChainTests.allTests),
        testCase(ArrayTests.allTests),
        testCase(ArrayValidatorIndexTests.allTests),
        testCase(ArrayValidatorTests.allTests),
        testCase(SlotNumberTests.allTests),
        testCase(EpochNumberTests.allTests),
        testCase(ValidatorTests.allTests),
//        testCase(StateTransitionTests.allTests)
    ]
}
#endif
