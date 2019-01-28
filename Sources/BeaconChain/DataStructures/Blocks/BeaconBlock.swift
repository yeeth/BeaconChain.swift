import Foundation

struct BeaconBlock {
    let slot: UInt64
    let parentRoot: Data
    let stateRoot: Data
    let randaoReveal: Data
    let eth1Data: Eth1Data
    let signature: Data
    let body: BeaconBlockBody
}
