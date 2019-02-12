import Foundation

struct Crosslink: Equatable {
    let epoch: UInt64
    let shardBlockRoot: Data
}
