import Foundation

struct ValidatorRegistryDeltaBlock {
    let lateRegistryDeltaRoot: Data
    let validatorIndex: Int
    let pubkey: Data
    let slot: UInt64
    let flag: ValidatorRegistryDeltaFlags
}
