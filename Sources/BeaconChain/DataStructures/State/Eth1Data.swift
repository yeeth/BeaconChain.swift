import Foundation

struct Eth1Data: Equatable {
    let depositRoot: Data
    let blockHash: Data

    public static func == (lhs: Eth1Data, rhs: Eth1Data) -> Bool {
        return lhs.depositRoot == rhs.depositRoot && lhs.blockHash == rhs.blockHash
    }
}
