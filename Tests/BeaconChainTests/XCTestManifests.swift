import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BeaconChainTests.allTests),
        testCase(ArrayTests.allTests),
        testCase(ArrayValidatorIndexTests.allTests),
        testCase(ArrayValidatorTests.allTests),
//        testCase(StateTransitionTests.allTests)
    ]
}
#endif
