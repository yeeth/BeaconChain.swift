import Foundation

struct Crosslink {
    let shard: Shard
    let parentRoot: Hash
    let startEpoch: Epoch
    let endEpoch: Epoch
    let dataRoot: Hash
}
