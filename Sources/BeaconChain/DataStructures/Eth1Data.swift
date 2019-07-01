import Foundation

struct Eth1Data: Equatable {
    let depositRoot: Data
    let depositCount: UInt64
    let blockHash: Data
}
