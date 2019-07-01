import Foundation

public struct BeaconBlock: Equatable {
    let slot: Slot
    let parentRoot: Data
    let stateRoot: Data
    let body: BeaconBlockBody
    var signature: BLSSignature
}
