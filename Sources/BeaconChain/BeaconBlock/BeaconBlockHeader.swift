import Foundation

struct BeaconBlockHeader {
    let slot: Slot
    let parentRoot: Hash
    let stateRoot: Hash
    let bodyRoot: Hash
    let signature: BLSSignature
}
