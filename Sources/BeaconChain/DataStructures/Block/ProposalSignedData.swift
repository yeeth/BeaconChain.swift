import Foundation

public struct ProposalSignedData {
    let slot: UInt64
    let shard: UInt64
    let blockRoot: Data
}
