import Foundation

struct BeaconBlockHeader: Equatable {
    let slot: Slot
    let parentRoot: Data
    let stateRoot: Data
    let bodyRoot: Data
    let signature: BLSSignature
}
