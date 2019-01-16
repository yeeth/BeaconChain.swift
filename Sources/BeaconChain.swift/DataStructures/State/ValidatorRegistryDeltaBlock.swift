import Foundation

struct ValidatorRegistryDeltaBlock {
    let lateRegistryDeltaRoot: Data
    let validatorIndex: Int
    let pubkey: Data
    let slot: Int
    let flag: Int
}
