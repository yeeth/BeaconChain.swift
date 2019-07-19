import Foundation

// @todo this will be in a seperate library

class BLS {

    func verify(pubkey: Data, hash: Hash, signature: Data, domain: UInt64) -> Bool {
        return false
    }

    func verify(pubkeys: [Data], hashes: [Hash], signature: Data, domain: UInt64) -> Bool {
        return false
    }

    func aggregate(pubkeys: [Data]) -> Data {
        fatalError("not yet implemented")
    }
}
