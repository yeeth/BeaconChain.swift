import Foundation

public struct Checkpoint: Equatable {
    let epoch: Epoch
    let root: Hash
}
