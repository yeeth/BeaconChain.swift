import Foundation

struct Exit {
    let epoch: UInt64
    let validatorIndex: UInt32 // @todo should be uint 24
    let signature: Data
}
