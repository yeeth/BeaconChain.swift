import Foundation

struct Proposal: Equatable {
    let slot: UInt64
    let shard: UInt64
    let blockRoot: Data
    let signature: Data
}
