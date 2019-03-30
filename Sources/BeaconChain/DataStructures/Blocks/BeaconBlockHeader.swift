import Foundation

struct BeaconBlockHeader {
    let slot: UInt64
    let previousBlockRoot: Data
    let stateRoot: Data
    let blockBodyRoot: Data
    let signature: Data
}
