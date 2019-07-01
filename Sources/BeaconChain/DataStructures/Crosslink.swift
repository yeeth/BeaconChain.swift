import Foundation

struct Crosslink: Equatable {
    let shard: Shard
    let parentRoot: Data
    let startEpoch: Epoch
    let endEpoch: Epoch
    let dataRoot: Data
}
