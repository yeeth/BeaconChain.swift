import Foundation

struct BeaconBlock: Comparable {
    let slot: UInt64
    let parentRoot: Data
    let stateRoot: Data
    let randaoReveal: Data
    let eth1Data: Eth1Data
    let body: BeaconBlockBody
    var signature: Data
}
