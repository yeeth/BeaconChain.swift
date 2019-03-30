import Foundation

class Merkle {

    func verifyBranch(leaf: Bytes32, proof: [Bytes32], depth: Int, index: Int, root: Bytes32) -> Bool {
        var value = leaf

        for i in 0..<depth {
            if index / (2**i) % 2 != 0 {
                value = BeaconChain.hash(proof[i] + value)
            } else {
                value = BeaconChain.hash(value + proof[i])
            }
        }

        return value == root
    }

}
