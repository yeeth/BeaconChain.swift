import Foundation

struct Block {
    let slot: Int
    let parentRoot: Data
    let stateRoot: Data
    let randaoReveal: Data
    let depositRoot: Data
    let eth1Data: Eth1Data
    var signature: Data
    let body: BlockBody
}
