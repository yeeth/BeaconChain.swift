import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(BeaconChainTests.allTests),
        testCase(StateTransitionTests.allTests)
    ]
}
#endif
