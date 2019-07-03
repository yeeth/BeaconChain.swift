import Foundation

struct BeaconBlock {
    let slot: Slot
    let parentRoot: Hash
    let stateRoot: Hash
    let body: BeaconBlockBody
    let signature: BLSSignature
}
