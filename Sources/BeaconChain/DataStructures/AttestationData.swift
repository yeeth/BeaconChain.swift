import Foundation

struct AttestationData: Equatable {
    let beaconBlockRoot: Data
    let source: Checkpoint
    let target: Checkpoint
    let crosslink: Crosslink

    func isSlashable(data: AttestationData) -> Bool {
        return (self != data && target.epoch == data.target.epoch)
                || (source.epoch < data.source.epoch && data.target.epoch < target.epoch)
    }

}
