import Foundation

struct Checkpoint: Equatable {
    let epoch: Epoch
    let hash: Data // @todo create hash type
}
