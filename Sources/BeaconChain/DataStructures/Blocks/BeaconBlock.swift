import Foundation

public struct BeaconBlock: Equatable {
    let slot: UInt64
    let previousBlockRoot: Data
    let stateRoot: Data
    let body: BeaconBlockBody
    var signature: Data
}
