import Foundation

public class Eth1Data: Equatable {
    let depositRoot: Data
    let blockHash: Data

    init(depositRoot: Data, blockHash: Data) {
        self.depositRoot = depositRoot
        self.blockHash = blockHash
    }

    public static func == (lhs: Eth1Data, rhs: Eth1Data) -> Bool {
        return lhs.blockHash == rhs.blockHash && lhs.depositRoot == rhs.depositRoot
    }
}
