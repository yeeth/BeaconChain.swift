import Foundation

struct BeaconBlockHeader {
    let slot: UInt64
    let previousBlockRoot: Data
    let stateRoot: Data
    let blockBodyRoot: Data
    let signature: Data

    init(block: BeaconBlock) {
        slot = block.slot
        previousBlockRoot = block.previousBlockRoot
        stateRoot = ZERO_HASH
        blockBodyRoot = BeaconChain.hashTreeRoot(block.body)
        signature = block.signature
    }
}
