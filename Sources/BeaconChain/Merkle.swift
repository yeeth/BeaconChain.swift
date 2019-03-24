import Foundation

class Merkle {

    static func root(_ values: [Bytes32]) -> Bytes32 {
        var o = [Data](repeating: Data(repeating: 0, count: 1), count: values.count - 1)
        o.append(contentsOf: values)

        for i in stride(from: values.count - 1, through: 0, by: -1) {
            o[i] = BeaconChain.hash(o[i * 2] + o[i * 2 + 1])
        }

        return o[1]
    }

    static func verifyBranch(leaf: Bytes32, branch: [Bytes32], depth: Int, index: Int, root: Bytes32) -> Bool {
        var value = leaf
        for i in 0..<depth {
            if index / (2 ** i) % 2 == 1 {
                value = BeaconChain.hash(branch[i] + value)
            } else {
                value = BeaconChain.hash(value + branch[i])
            }
        }

        return value == root
    }
}
