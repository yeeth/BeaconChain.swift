import Foundation

struct Proposal {
    let slot: UInt64
    let shard: UInt64
    let blockRoot: Data
    let signature: Data
}
