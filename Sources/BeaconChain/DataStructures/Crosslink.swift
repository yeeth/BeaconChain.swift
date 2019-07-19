import Foundation

public struct Crosslink: Equatable {
    let shard: Shard
    let parentRoot: Hash
    let startEpoch: Epoch
    let endEpoch: Epoch
    let dataRoot: Hash
}
